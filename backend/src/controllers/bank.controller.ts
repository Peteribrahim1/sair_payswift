import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import { verifyAccountNumber, createTransferRecipient } from '../services/paystack.service';

export const addBankAccount = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const { accountNumber, bankCode, bankName } = req.body;

  if (!accountNumber || !bankCode || !bankName) {
    return res.status(400).json({ error: 'Missing required bank details' });
  }

  try {
    // 1. Verify account number via Paystack
    const accountName = await verifyAccountNumber(accountNumber, bankCode);

    // 2. Create Transfer Recipient via Paystack
    const recipientCode = await createTransferRecipient(accountName, accountNumber, bankCode);

    // 3. Save to database
    const bankAccount = await prisma.bankAccount.create({
      data: {
        userId,
        accountNumber,
        accountName,
        bankCode,
        bankName,
        recipientCode,
      },
    });

    res.json({ success: true, bankAccount });
  } catch (error: any) {
    res.status(400).json({ error: error.message || 'Failed to add bank account' });
  }
};

export const getBankAccounts = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  try {
    const accounts = await prisma.bankAccount.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    // Mask the account numbers before sending
    const maskedAccounts = accounts.map(acc => ({
      id: acc.id,
      bankName: acc.bankName,
      accountName: acc.accountName,
      number: `${acc.accountNumber.substring(0, 4)}****${acc.accountNumber.substring(acc.accountNumber.length - 2)}`,
    }));

    res.json({ success: true, bankAccounts: maskedAccounts });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to fetch bank accounts' });
  }
};

export const deleteBankAccount = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const { id } = req.params;

  try {
    await prisma.bankAccount.deleteMany({
      where: { id, userId },
    });
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message || 'Failed to delete bank account' });
  }
};
