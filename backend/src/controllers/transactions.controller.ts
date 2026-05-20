import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

// ─── POST /api/transactions/withdraw ──────────────────────────────────────────
export const withdrawFunds = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const { amount, bankName, accountNumber } = req.body;

  if (!amount || amount <= 0) {
    return res.status(400).json({ error: 'Valid amount is required' });
  }

  if (!bankName || !accountNumber) {
    return res.status(400).json({ error: 'Bank details are required' });
  }

  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (user.balance < amount) {
      return res.status(400).json({ error: 'Insufficient wallet balance' });
    }

    // Process atomically
    await prisma.$transaction([
      prisma.user.update({
        where: { id: userId },
        data: { balance: { decrement: amount } },
      }),
      prisma.transaction.create({
        data: {
          userId,
          type: 'WITHDRAWAL',
          amount,
          status: 'COMPLETED',
        },
      }),
      prisma.notification.create({
        data: {
          userId,
          title: 'Withdrawal Successful',
          message: `You have successfully withdrawn ₦${amount.toFixed(2)} to ${bankName} (${accountNumber}).`,
        },
      }),
    ]);

    // Fetch the updated user and transaction to return
    const updatedUser = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        transactions: { orderBy: { createdAt: 'desc' }, take: 20 },
      },
    });

    return res.json({
      success: true,
      balance: updatedUser?.balance,
      transaction: updatedUser?.transactions[0],
    });
  } catch (error: any) {
    console.error('Withdrawal error:', error);
    res.status(500).json({ error: error.message || 'Withdrawal failed' });
  }
};
