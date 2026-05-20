import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import { initiateTransfer } from '../services/paystack.service';
import crypto from 'crypto';

// ─── POST /api/transactions/withdraw ──────────────────────────────────────────
export const withdrawFunds = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const { amount, bankAccountId } = req.body;

  if (!amount || amount <= 0) {
    return res.status(400).json({ error: 'Valid amount is required' });
  }

  if (!bankAccountId) {
    return res.status(400).json({ error: 'Bank account is required' });
  }

  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (user.balance < amount) {
      return res.status(400).json({ error: 'Insufficient wallet balance' });
    }

    const bankAccount = await prisma.bankAccount.findFirst({
      where: { id: bankAccountId, userId },
    });

    if (!bankAccount) {
      return res.status(404).json({ error: 'Bank account not found' });
    }

    // Initiate Transfer via Paystack
    const reference = crypto.randomBytes(16).toString('hex');
    const transferResult = await initiateTransfer(amount, bankAccount.recipientCode, reference);

    if (transferResult.status !== 'success' && transferResult.status !== 'pending') {
      throw new Error(`Transfer failed: ${transferResult.status}`);
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
          reference: transferResult.reference || reference,
        },
      }),
      prisma.notification.create({
        data: {
          userId,
          title: 'Withdrawal Processed',
          message: `Your withdrawal of ₦${amount.toFixed(2)} to ${bankAccount.bankName} is being processed.`,
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
