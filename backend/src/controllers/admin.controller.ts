import { Request, Response } from 'express';
import { prisma } from '../prisma';

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
