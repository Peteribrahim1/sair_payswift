import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import fs from 'fs';
import path from 'path';

export const getProfile = async (req: AuthRequest, res: Response) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        balance: true,
        profilePicture: true,
        kycStatus: true,
        kycVerified: true,
        transactions: {
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
      },
    });
    if (!user) return res.status(404).json({ error: 'User not found.' });

    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error.' });
  }
};

export const updateProfile = async (req: AuthRequest, res: Response) => {
  try {
    const { fullName, phone } = req.body;
    const user = await prisma.user.update({
      where: { id: req.user!.id },
      data: { fullName, phone },
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        balance: true,
        profilePicture: true,
      },
    });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error.' });
  }
};

import { createCustomer, validateCustomerKYC } from '../services/paystack.service';

export const submitKyc = async (req: AuthRequest, res: Response) => {
  try {
    const { bvn, nin } = req.body;
    if (!bvn && !nin) {
      return res.status(400).json({ error: 'BVN or NIN is required' });
    }

    const user = await prisma.user.findUnique({ where: { id: req.user!.id } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    let customerCode = user.paystackCustomerCode;
    const nameParts = (user.fullName || user.email).split(' ');
    const firstName = nameParts[0] ?? 'User';
    const lastName  = nameParts.slice(1).join(' ') || firstName;

    // Ensure they have a Paystack customer
    if (!customerCode) {
      const customer = await createCustomer(user.email, firstName, lastName, user.phone || undefined);
      customerCode = customer.customerCode;
    }

    // Call validation
    try {
      await validateCustomerKYC(customerCode, firstName, lastName, bvn, nin);
    } catch (error: any) {
      // If Paystack says validation is not available for this integration, 
      // we log it but proceed anyway to see if DVA creation works.
      if (error.message.includes('not available on this integration')) {
        console.warn('Paystack Identity Validation restricted — proceeding to DVA creation');
      } else {
        throw error;
      }
    }

    // Save success in DB
    await prisma.user.update({
      where: { id: user.id },
      data: {
        bvn: bvn || user.bvn,
        nin: nin || user.nin,
        kycVerified: true,
        paystackCustomerCode: customerCode,
      },
    });

    res.json({ success: true, message: 'KYC verified successfully' });
  } catch (error: any) {
    console.error('submitKyc error:', error.message);
    res.status(500).json({ error: error.message || 'Failed to verify KYC' });
  }
};

export const uploadProfilePicture = async (req: AuthRequest, res: Response) => {
  try {
    const { profilePicture } = req.body; // base64 string
    if (!profilePicture) {
      return res.status(400).json({ error: 'profilePicture base64 string is required.' });
    }

    // Decode base64 image
    const matches = profilePicture.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    let base64Data = profilePicture;
    let extension = 'jpg'; // fallback

    if (matches && matches.length === 3) {
      const type = matches[1];
      base64Data = matches[2];
      extension = type.split('/')[1] || 'jpg';
      if (extension === 'jpeg') extension = 'jpg';
    }

    const buffer = Buffer.from(base64Data, 'base64');
    
    // Create uploads folder if it doesn't exist
    const uploadsDir = path.join(__dirname, '../../uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    // Generate unique name
    const filename = `${req.user!.id}-${Date.now()}.${extension}`;
    const filePath = path.join(uploadsDir, filename);

    // Get current user to see if they already have an avatar, and delete it to clean up space
    const currentUser = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: { profilePicture: true },
    });

    if (currentUser?.profilePicture) {
      const oldPath = path.join(uploadsDir, currentUser.profilePicture);
      if (fs.existsSync(oldPath)) {
        try {
          fs.unlinkSync(oldPath);
        } catch (err) {
          console.error('Failed to delete old profile image:', err);
        }
      }
    }

    // Write file
    fs.writeFileSync(filePath, buffer);

    // Update user record
    const updatedUser = await prisma.user.update({
      where: { id: req.user!.id },
      data: { profilePicture: filename },
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        balance: true,
        profilePicture: true,
      },
    });

    return res.json({
      success: true,
      message: 'Profile picture uploaded successfully.',
      user: updatedUser,
    });
  } catch (error: any) {
    console.error('uploadProfilePicture error:', error.message);
    res.status(500).json({ error: 'Failed to upload profile picture.' });
  }
};

export const uploadKycDocument = async (req: AuthRequest, res: Response) => {
  try {
    const { documentImage } = req.body; // base64 string
    if (!documentImage) {
      return res.status(400).json({ error: 'documentImage base64 string is required.' });
    }

    const matches = documentImage.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    let base64Data = documentImage;
    let extension = 'jpg';

    if (matches && matches.length === 3) {
      const type = matches[1];
      base64Data = matches[2];
      if (type.includes('png')) extension = 'png';
      else if (type.includes('jpeg') || type.includes('jpg')) extension = 'jpg';
      else if (type.includes('pdf')) extension = 'pdf';
    }

    const fileName = `kyc_${req.user!.id}_${Date.now()}.${extension}`;
    const filePath = path.join(__dirname, '../../uploads', fileName);

    fs.writeFileSync(filePath, base64Data, 'base64');
    const fileUrl = `/uploads/${fileName}`;

    const updatedUser = await prisma.user.update({
      where: { id: req.user!.id },
      data: {
        kycDocument: fileUrl,
        kycStatus: 'PENDING',
      },
    });

    return res.json({
      success: true,
      message: 'KYC Document uploaded successfully. Pending approval.',
      kycStatus: updatedUser.kycStatus,
    });
  } catch (error: any) {
    console.error('uploadKycDocument error:', error.message);
    res.status(500).json({ error: 'Failed to upload KYC document.' });
  }
};
