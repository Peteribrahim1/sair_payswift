import { Request, Response } from 'express';
import { prisma } from '../prisma';
import * as admin from 'firebase-admin';

// Simple middleware/helper to check admin passcode header
const verifyAdminPasscode = (req: Request): boolean => {
  return req.headers['x-admin-secret'] === 'sair-sandbox-test-2026';
};

export const getAdminUsers = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const users = await prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        fullName: true,
        phone: true,
        balance: true,
        kycVerified: true,
        createdAt: true,
      }
    });
    res.json({ success: true, users });
  } catch (error) {
    console.error('getAdminUsers error:', error);
    res.status(500).json({ error: 'Internal server error.' });
  }
};

export const getAdminTransactions = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const transactions = await prisma.transaction.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            email: true,
            fullName: true,
          }
        }
      }
    });
    res.json({ success: true, transactions });
  } catch (error) {
    console.error('getAdminTransactions error:', error);
    res.status(500).json({ error: 'Internal server error.' });
  }
};

export const getAdminTickets = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const tickets = await prisma.ticket.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            email: true,
            fullName: true,
            phone: true,
          }
        }
      }
    });
    res.json({ success: true, tickets });
  } catch (error) {
    console.error('getAdminTickets error:', error);
    res.status(500).json({ error: 'Internal server error.' });
  }
};

export const resolveAdminTicket = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const { id } = req.params;
    const ticket = await prisma.ticket.update({
      where: { id },
      data: { status: 'RESOLVED' }
    });

    // Also trigger an automatic user notification that the issue was resolved
    await prisma.notification.create({
      data: {
        userId: ticket.userId,
        title: 'Support Issue Resolved',
        message: `Your support ticket regarding "${ticket.subject}" has been marked as resolved by our support staff.`
      }
    });

    res.json({ success: true, ticket });
  } catch (error) {
    console.error('resolveAdminTicket error:', error);
    res.status(500).json({ error: 'Internal server error.' });
  }
};

// ─── AIRTIME TO CASH APPROVALS ────────────────────────────────────────────────
export const getPendingAirtime = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const transactions = await prisma.transaction.findMany({
      where: { type: 'CONVERT_AIRTIME', status: 'PENDING' },
      include: { user: { select: { fullName: true, email: true, phone: true } } },
      orderBy: { createdAt: 'desc' }
    });
    res.json({ success: true, transactions });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch airtime transactions' });
  }
};

export const approveAirtime = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });
  const { id } = req.params;
  try {
    const transaction = await prisma.transaction.findUnique({ where: { id } });
    if (!transaction || transaction.status !== 'PENDING') {
      return res.status(400).json({ error: 'Transaction not pending or not found' });
    }

    await prisma.$transaction([
      prisma.transaction.update({
        where: { id },
        data: { status: 'COMPLETED' }
      }),
      prisma.user.update({
        where: { id: transaction.userId },
        data: { balance: { increment: transaction.amount } }
      }),
      prisma.notification.create({
        data: {
          userId: transaction.userId,
          title: 'Airtime Converted',
          message: `Your airtime to cash conversion of ₦${transaction.amount} was approved and credited.`
        }
      })
    ]);

    res.json({ success: true, message: 'Approved and credited.' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to approve airtime' });
  }
};

export const rejectAirtime = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });
  const { id } = req.params;
  try {
    const transaction = await prisma.transaction.findUnique({ where: { id } });
    if (!transaction || transaction.status !== 'PENDING') {
      return res.status(400).json({ error: 'Transaction not pending or not found' });
    }

    await prisma.$transaction([
      prisma.transaction.update({
        where: { id },
        data: { status: 'FAILED' }
      }),
      prisma.notification.create({
        data: {
          userId: transaction.userId,
          title: 'Airtime Conversion Failed',
          message: `Your airtime to cash conversion of ₦${transaction.amount} was rejected.`
        }
      })
    ]);

    res.json({ success: true, message: 'Rejected.' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to reject airtime' });
  }
};

// ─── SYSTEM SETTINGS & PRICING ────────────────────────────────────────────────
export const getSystemSettings = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  try {
    let config = await prisma.appConfig.findUnique({ where: { id: 'global-config' } });
    if (!config) {
      config = await prisma.appConfig.create({
        data: {
          id: 'global-config',
          dataMarkupPercent: 5.0,
          airtimeMarkupPercent: 2.0,
          airtimeToCashRate: 70.0,
          billConvenienceFee: 50.0
        }
      });
    }
    res.json({ success: true, settings: config });
  } catch (error) {
    console.error('getSystemSettings error:', error);
    res.status(500).json({ error: 'Failed to fetch settings' });
  }
};

export const updateSystemSettings = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const { dataMarkupPercent, airtimeMarkupPercent, airtimeToCashRate, billConvenienceFee } = req.body;
    
    const config = await prisma.appConfig.upsert({
      where: { id: 'global-config' },
      update: {
        dataMarkupPercent: Number(dataMarkupPercent),
        airtimeMarkupPercent: Number(airtimeMarkupPercent),
        airtimeToCashRate: Number(airtimeToCashRate),
        billConvenienceFee: Number(billConvenienceFee)
      },
      create: {
        id: 'global-config',
        dataMarkupPercent: Number(dataMarkupPercent),
        airtimeMarkupPercent: Number(airtimeMarkupPercent),
        airtimeToCashRate: Number(airtimeToCashRate),
        billConvenienceFee: Number(billConvenienceFee)
      }
    });

    res.json({ success: true, settings: config, message: 'Settings updated successfully' });
  } catch (error) {
    console.error('updateSystemSettings error:', error);
    res.status(500).json({ error: 'Failed to update settings' });
  }
};

export const manuallyFundUser = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });
  
  const { id } = req.params;
  const { amount, action, reason } = req.body;

  if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) {
    return res.status(400).json({ error: 'Invalid amount' });
  }
  if (action !== 'CREDIT' && action !== 'DEBIT') {
    return res.status(400).json({ error: 'Invalid action. Must be CREDIT or DEBIT.' });
  }

  try {
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const adjustment = action === 'CREDIT' ? Number(amount) : -Number(amount);
    
    if (action === 'DEBIT' && user.balance < Number(amount)) {
      return res.status(400).json({ error: `Cannot debit ₦${amount}. User only has ₦${user.balance}.` });
    }

    const result = await prisma.$transaction([
      prisma.user.update({
        where: { id },
        data: { balance: { increment: adjustment } }
      }),
      prisma.transaction.create({
        data: {
          userId: id,
          amount: Number(amount),
          type: action === 'CREDIT' ? 'FUND' : 'WITHDRAW',
          reference: `ADMIN_${action}_${Date.now()}`,
          status: 'SUCCESS',
          details: reason || `Manual Admin ${action}`,
        }
      })
    ]);

    res.json({ success: true, user: result[0], transaction: result[1] });
  } catch (error) {
    console.error('manuallyFundUser error:', error);
    res.status(500).json({ error: 'Failed to manually adjust user balance' });
  }
};

export const getPendingKyc = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const users = await prisma.user.findMany({
      where: { kycStatus: 'PENDING' },
      select: {
        id: true,
        fullName: true,
        email: true,
        bvn: true,
        nin: true,
        kycDocument: true,
        kycStatus: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' }
    });
    res.json({ success: true, users });
  } catch (error) {
    console.error('getPendingKyc error:', error);
    res.status(500).json({ error: 'Failed to fetch pending KYC' });
  }
};

export const approveKyc = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  const { id } = req.params;
  try {
    const user = await prisma.user.update({
      where: { id },
      data: { kycStatus: 'VERIFIED', kycVerified: true }
    });
    res.json({ success: true, user });
  } catch (error) {
    console.error('approveKyc error:', error);
    res.status(500).json({ error: 'Failed to approve KYC' });
  }
};

export const rejectKyc = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  const { id } = req.params;
  try {
    const user = await prisma.user.update({
      where: { id },
      data: { kycStatus: 'REJECTED', kycVerified: false, kycDocument: null }
    });
    // Optional: delete the file from disk using fs.unlinkSync if you want.
    res.json({ success: true, user });
  } catch (error) {
    console.error('rejectKyc error:', error);
    res.status(500).json({ error: 'Failed to reject KYC' });
  }
};

import { firebaseInitError } from '../index';

export const broadcastNotification = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });
  
  const { title, message } = req.body;
  if (!title || !message) {
    return res.status(400).json({ error: 'Title and message are required' });
  }

  try {
    const users = await prisma.user.findMany({ select: { id: true, fcmToken: true } });
    if (users.length === 0) {
      return res.json({ success: true, message: 'No users found to broadcast to.' });
    }

    const notifications = users.map(u => ({
      userId: u.id,
      title,
      message,
    }));

    await prisma.notification.createMany({
      data: notifications,
    });

    // Send FCM push notifications to all users who have an fcmToken
    const tokens = users.map(u => u.fcmToken).filter(token => token !== null) as string[];
    
    let pushResultMsg = '';
    if (tokens.length > 0) {
      try {
        if (admin.apps.length === 0) {
          throw new Error(`Firebase not initialized. Init Error: ${firebaseInitError?.message || firebaseInitError || 'Unknown'}`);
        }
        const response = await admin.messaging().sendEachForMulticast({
          tokens,
          notification: { title, body: message }
        });
        pushResultMsg = ` Also sent push notifications (Success: ${response.successCount}, Failed: ${response.failureCount}).`;
      } catch (fcmErr: any) {
        console.error('FCM Multicast error:', fcmErr.message);
        pushResultMsg = ` But failed to send push notifications: ${fcmErr.message}`;
      }
    }

    res.json({ success: true, message: `Broadcast saved to ${users.length} inboxes.${pushResultMsg}` });
  } catch (error: any) {
    console.error('broadcastNotification error:', error.message);
    res.status(500).json({ error: 'Failed to send broadcast.' });
  }
};

// ─── Advert Management ────────────────────────────────────────────────────────

export const getAdminAdverts = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const adverts = await prisma.advert.findMany({
      orderBy: { createdAt: 'desc' }
    });
    res.json({ success: true, adverts });
  } catch (error: any) {
    console.error('getAdminAdverts error:', error);
    res.status(500).json({ error: 'Failed to fetch adverts' });
  }
};

export const createAdvert = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  const { title, description, ctaText, tag, themeColor, iconName, actionKey, isActive } = req.body;

  if (!title || !description || !themeColor || !iconName) {
    return res.status(400).json({ error: 'Missing required advert fields' });
  }

  try {
    const advert = await prisma.advert.create({
      data: {
        title,
        description,
        ctaText: ctaText || 'Learn More',
        tag: tag || 'SPONSORED',
        themeColor,
        iconName,
        actionKey: actionKey || 'none',
        isActive: isActive !== undefined ? isActive : true,
      }
    });
    res.json({ success: true, advert });
  } catch (error: any) {
    console.error('createAdvert error:', error);
    res.status(500).json({ error: 'Failed to create advert' });
  }
};

export const deleteAdvert = async (req: Request, res: Response) => {
  if (!verifyAdminPasscode(req)) return res.status(401).json({ error: 'Unauthorized' });

  const { id } = req.params;

  try {
    await prisma.advert.delete({ where: { id } });
    res.json({ success: true, message: 'Advert deleted successfully' });
  } catch (error: any) {
    console.error('deleteAdvert error:', error);
    res.status(500).json({ error: 'Failed to delete advert' });
  }
};
