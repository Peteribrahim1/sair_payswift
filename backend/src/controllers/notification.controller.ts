import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export const getNotifications = async (req: AuthRequest, res: Response) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user!.id },
      orderBy: { createdAt: 'desc' },
    });
    res.json(notifications);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error.' });
  }
};

export const markNotificationRead = async (req: AuthRequest, res: Response) => {
  try {
    const id = req.params.id as string;
    const notification = await prisma.notification.updateMany({
      where: { id, userId: req.user!.id },
      data: { read: true },
    });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error.' });
  }
};
