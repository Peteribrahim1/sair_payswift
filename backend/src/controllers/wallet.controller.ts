import { Request, Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import {
  createCustomer,
  createDVA,
  fetchDVA,
  verifyWebhookSignature,
} from '../services/paystack.service';

// ─── GET /api/wallet/virtual-account ─────────────────────────────────────────
// Returns (or provisions) the user's dedicated virtual account
export const getVirtualAccount = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;

  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Enforce KYC
    if (!user.kycVerified) {
      return res.status(403).json({ error: 'KYC validation required', requireKyc: true });
    }

    // Already provisioned — return stored details
    if (user.virtualAccountNumber) {
      return res.json({
        accountNumber: user.virtualAccountNumber,
        bankName: user.virtualAccountBank,
        accountName: user.virtualAccountName,
      });
    }

    // Need to provision — create Paystack customer first
    let customerCode = user.paystackCustomerCode;

    if (!customerCode) {
      const nameParts = (user.fullName || user.email).split(' ');
      const firstName = nameParts[0] ?? 'User';
      const lastName  = nameParts.slice(1).join(' ') || firstName;
      const customer  = await createCustomer(user.email, firstName, lastName, user.phone || undefined);
      customerCode    = customer.customerCode;
    }

    // Try fetching an existing DVA for this customer first
    let dva = await fetchDVA(customerCode);

    // If none exists yet, create one
    if (!dva) {
      const nameParts = (user.fullName || user.email).split(' ');
      const firstName = nameParts[0] ?? 'User';
      const lastName  = nameParts.slice(1).join(' ') || '';
      const fullName  = lastName ? `${firstName} ${lastName}` : firstName;
      dva = await createDVA(customerCode, fullName);
    }

    // Persist to DB
    await prisma.user.update({
      where: { id: userId },
      data: {
        paystackCustomerCode: customerCode,
        virtualAccountNumber: dva.accountNumber,
        virtualAccountBank:   dva.bankName,
        virtualAccountName:   dva.accountName,
      },
    });

    return res.json({
      accountNumber: dva.accountNumber,
      bankName:      dva.bankName,
      accountName:   dva.accountName,
    });
  } catch (error: any) {
    console.error('getVirtualAccount error:', error.message);
    res.status(500).json({ error: error.message || 'Failed to get virtual account' });
  }
};

// ─── POST /api/wallet/webhook ─────────────────────────────────────────────────
// Paystack calls this when a transfer/charge succeeds on a DVA
export const handleWebhook = async (req: Request, res: Response) => {
  // Always respond 200 immediately so Paystack doesn't retry
  res.sendStatus(200);

  const signature = req.headers['x-paystack-signature'] as string ?? '';
  const rawBody   = JSON.stringify(req.body);

  // Reject invalid signatures
  if (!verifyWebhookSignature(rawBody, signature)) {
    console.warn('[Webhook] Invalid Paystack signature — ignored');
    return;
  }

  const event = req.body;

  // Only handle successful dedicated-account charges
  if (event.event !== 'charge.success') return;
  if (event.data?.channel !== 'dedicated_nuban') return;

  const customerCode  = event.data?.customer?.customer_code as string | undefined;
  const amountKobo    = event.data?.amount as number | undefined; // Paystack sends kobo
  const paystackRef   = event.data?.reference as string | undefined;

  if (!customerCode || !amountKobo || !paystackRef) {
    console.warn('[Webhook] Missing fields in charge.success payload');
    return;
  }

  const amountNaira = amountKobo / 100;

  try {
    const user = await prisma.user.findFirst({
      where: { paystackCustomerCode: customerCode },
    });

    if (!user) {
      console.warn(`[Webhook] No user found for customerCode: ${customerCode}`);
      return;
    }

    // Guard against duplicate webhook delivery
    const existing = await prisma.transaction.findFirst({
      where: { reference: paystackRef },
    });
    if (existing) {
      console.log(`[Webhook] Duplicate webhook for ref ${paystackRef} — skipped`);
      return;
    }

    // Credit wallet atomically
    await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data:  { balance: { increment: amountNaira } },
      }),
      prisma.transaction.create({
        data: {
          userId:    user.id,
          amount:    amountNaira,
          type:      'FUND',
          status:    'COMPLETED',
          reference: paystackRef,
        },
      }),
      prisma.notification.create({
        data: {
          userId:  user.id,
          title:   'Wallet Funded',
          message: `₦${amountNaira.toLocaleString()} has been added to your wallet.`,
        },
      }),
    ]);

    console.log(`[Webhook] ✅ Credited ₦${amountNaira} to user ${user.email}`);
  } catch (error: any) {
    console.error('[Webhook] Error processing payment:', error.message);
  }
};
