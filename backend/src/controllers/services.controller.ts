import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export const transact = async (req: AuthRequest, res: Response) => {
  const { amount, type } = req.body; // type: AIRTIME, DATA, BILL
  const userId = req.user!.id;

  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.balance < amount) return res.status(400).json({ error: 'Insufficient balance' });

    // Use a transaction
    const result = await prisma.$transaction([
      prisma.user.update({
        where: { id: userId },
        data: { balance: { decrement: amount } },
      }),
      prisma.transaction.create({
        data: {
          userId,
          amount,
          type,
          status: 'COMPLETED',
        },
      }),
    ]);

    res.json({ success: true, balance: result[0].balance, transaction: result[1] });
  } catch (error) {
    res.status(500).json({ error: 'Transaction failed' });
  }
};
