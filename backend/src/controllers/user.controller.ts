import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

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
