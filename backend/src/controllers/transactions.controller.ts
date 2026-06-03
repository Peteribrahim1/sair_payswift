import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import { initiateTransfer } from '../services/paystack.service';
import crypto from 'crypto';

// ─── POST /api/transactions/withdraw ──────────────────────────────────────────
export const withdrawFunds = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const { amount, bankAccountId } = req.body;

  const rawAmount = parseFloat(amount?.toString() || '0');
  if (isNaN(rawAmount) || rawAmount <= 0) {
    return res.status(400).json({ error: 'Valid amount is required' });
  }

  if (!bankAccountId) {
    return res.status(400).json({ error: 'Bank account is required' });
  }

  try {
    const bankAccount = await prisma.bankAccount.findFirst({
      where: { id: bankAccountId, userId },
    });

    if (!bankAccount) {
      return res.status(404).json({ error: 'Bank account not found' });
    }

    // 1. Atomically debit wallet
    const debitResult = await prisma.user.updateMany({
      where: { id: userId, balance: { gte: rawAmount } },
      data: { balance: { decrement: rawAmount } },
    });

    if (debitResult.count === 0) {
      return res.status(400).json({ error: 'Insufficient wallet balance' });
    }

    const reference = crypto.randomBytes(16).toString('hex');
    const tx = await prisma.transaction.create({
      data: {
        userId,
        type: 'WITHDRAWAL',
        amount: rawAmount,
        status: 'PENDING',
        reference,
      },
    });

    try {
      // 2. Initiate Transfer via Paystack
      const transferResult = await initiateTransfer(rawAmount, bankAccount.recipientCode, reference);

      if (transferResult.status !== 'success' && transferResult.status !== 'pending') {
        throw new Error(`Transfer failed: ${transferResult.status}`);
      }

      // 3. Complete and notify
      await prisma.$transaction([
        prisma.transaction.update({
          where: { id: tx.id },
          data: { status: 'COMPLETED', reference: transferResult.reference || reference },
        }),
        prisma.notification.create({
          data: {
            userId,
            title: 'Withdrawal Processed',
            message: `Your withdrawal of ₦${rawAmount.toFixed(2)} to ${bankAccount.bankName} is being processed.`,
          },
        }),
      ]);

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
    } catch (apiError: any) {
      // Refund if Paystack initiation fails
      await prisma.$transaction([
        prisma.user.update({
          where: { id: userId },
          data: { balance: { increment: rawAmount } },
        }),
        prisma.transaction.update({
          where: { id: tx.id },
          data: { status: 'FAILED' },
        }),
      ]);
      throw new Error(apiError.message || 'Withdrawal failed at provider');
    }
  } catch (error: any) {
    console.error('Withdrawal error:', error);
    res.status(500).json({ error: error.message || 'Withdrawal failed' });
  }
};
