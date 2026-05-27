import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import {
  AIRTIME_SERVICE_IDS,
  DATA_SERVICE_IDS,
  ELECTRICITY_SERVICE_IDS,
  CABLE_SERVICE_IDS,
  vtpassBuyAirtime,
  vtpassBuyData,
  vtpassGetDataVariations,
  vtpassPayElectricity,
  vtpassPayCableTV,
  vtpassGetCablePlans,
  vtpassVerifySmartCard,
} from '../services/vtpass.service';
import { AirtimeCashService } from '../services/airtime-cash.service';

// ─── Helper: deduct wallet & log transaction ─────────────────────────────────
async function recordTransaction(
  userId: string,
  amount: number,
  type: string,
  reference: string,
  phone?: string,
  network?: string,
  notificationMsg?: string
) {
  return prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: { balance: { decrement: amount } },
    }),
    prisma.transaction.create({
      data: { userId, amount, type, status: 'COMPLETED', reference, phone, network },
    }),
    prisma.notification.create({
      data: {
        userId,
        title: 'Transaction Successful',
        message: notificationMsg ?? `Your ${type} transaction of ₦${amount} was successful.`,
      },
    }),
  ]);
}

// ─── GET /api/services/data-plans/:network ───────────────────────────────────
export const getDataPlans = async (req: AuthRequest, res: Response) => {
  const { network } = req.params;
  const serviceID = DATA_SERVICE_IDS[network];
  if (!serviceID) return res.status(400).json({ error: `Unknown network: ${network}` });

  try {
    const plans = await vtpassGetDataVariations(serviceID);
    res.json({ plans });
  } catch (error: any) {
    console.error('getDataPlans error:', error.message);
    res.status(500).json({ error: 'Failed to fetch data plans' });
  }
};

// ─── GET /api/services/cable-plans/:provider ─────────────────────────────────
export const getCablePlans = async (req: AuthRequest, res: Response) => {
  const { provider } = req.params;
  const serviceID = CABLE_SERVICE_IDS[provider];
  if (!serviceID) return res.status(400).json({ error: `Unknown provider: ${provider}` });

  try {
    const plans = await vtpassGetCablePlans(serviceID);
    res.json({ plans });
  } catch (error: any) {
    console.error('getCablePlans error:', error.message);
    res.status(500).json({ error: 'Failed to fetch cable plans' });
  }
};

// ─── POST /api/services/verify-smartcard ─────────────────────────────────────
export const verifySmartCard = async (req: AuthRequest, res: Response) => {
  const { provider, smartCardNumber } = req.body;
  const serviceID = CABLE_SERVICE_IDS[provider];
  if (!serviceID) return res.status(400).json({ error: `Unknown provider: ${provider}` });

  try {
    const info = await vtpassVerifySmartCard(serviceID, smartCardNumber);
    res.json({ info });
  } catch (error: any) {
    console.error('verifySmartCard error:', error.message);
    res.status(500).json({ error: 'Failed to verify smart card' });
  }
};

// ─── POST /api/services/verify-meter ─────────────────────────────────────────
export const verifyMeter = async (req: AuthRequest, res: Response) => {
  const { provider, meterNumber } = req.body;
  const serviceID = ELECTRICITY_SERVICE_IDS[provider];
  if (!serviceID) return res.status(400).json({ error: `Unknown provider: ${provider}` });

  try {
    const info = await vtpassVerifySmartCard(serviceID, meterNumber);
    res.json({ info });
  } catch (error: any) {
    console.error('verifyMeter error:', error.message);
    res.status(500).json({ error: 'Failed to verify meter number' });
  }
};

// ─── POST /api/services/airtime ──────────────────────────────────────────────
export const buyAirtime = async (req: AuthRequest, res: Response) => {
  const { network, phone, amount } = req.body;
  const userId = req.user!.id;

  if (!network || !phone || !amount) {
    return res.status(400).json({ error: 'network, phone and amount are required' });
  }

  const serviceID = AIRTIME_SERVICE_IDS[network];
  if (!serviceID) return res.status(400).json({ error: `Unknown network: ${network}` });

  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.balance < amount) return res.status(400).json({ error: 'Insufficient balance' });

    // Call VTPass
    const { requestId } = await vtpassBuyAirtime(serviceID, phone, amount);

    // Deduct & log
    const result = await recordTransaction(
      userId, amount, 'AIRTIME', requestId, phone, network,
      `₦${amount} airtime sent to ${phone} (${network})`
    );

    res.json({ success: true, balance: result[0].balance, transaction: result[1] });
  } catch (error: any) {
    console.error('buyAirtime error:', error.message);
    res.status(500).json({ error: error.message || 'Airtime purchase failed' });
  }
};

// ─── POST /api/services/data ─────────────────────────────────────────────────
export const buyData = async (req: AuthRequest, res: Response) => {
  const { network, phone, variationCode, amount } = req.body;
  const userId = req.user!.id;

  if (!network || !phone || !variationCode || !amount) {
    return res.status(400).json({ error: 'network, phone, variationCode and amount are required' });
  }

  const serviceID = DATA_SERVICE_IDS[network];
  if (!serviceID) return res.status(400).json({ error: `Unknown network: ${network}` });

  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.balance < amount) return res.status(400).json({ error: 'Insufficient balance' });

    // Call VTPass
    const { requestId } = await vtpassBuyData(serviceID, phone, variationCode, amount);

    // Deduct & log
    const result = await recordTransaction(
      userId, amount, 'DATA', requestId, phone, network,
      `₦${amount} data bundle sent to ${phone} (${network})`
    );

    res.json({ success: true, balance: result[0].balance, transaction: result[1] });
  } catch (error: any) {
    console.error('buyData error:', error.message);
    res.status(500).json({ error: error.message || 'Data purchase failed' });
  }
};

// ─── POST /api/services/electricity ──────────────────────────────────────────
export const payElectricity = async (req: AuthRequest, res: Response) => {
  const { provider, meterNumber, meterType, amount, phone } = req.body;
  const userId = req.user!.id;

  if (!provider || !meterNumber || !meterType || !amount || !phone) {
    return res.status(400).json({ error: 'provider, meterNumber, meterType, amount and phone are required' });
  }

  const serviceID = ELECTRICITY_SERVICE_IDS[provider];
  if (!serviceID) return res.status(400).json({ error: `Unknown provider: ${provider}` });

  const variationCode = meterType === 'prepaid' ? 'prepaid' : 'postpaid';

  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.balance < amount) return res.status(400).json({ error: 'Insufficient balance' });

    // Call VTPass
    const { requestId } = await vtpassPayElectricity(serviceID, meterNumber, variationCode, amount, phone);

    // Deduct & log
    const result = await recordTransaction(
      userId, amount, 'ELECTRICITY', requestId, phone, provider,
      `₦${amount} electricity payment for meter ${meterNumber} (${provider})`
    );

    res.json({ success: true, balance: result[0].balance, transaction: result[1] });
  } catch (error: any) {
    console.error('payElectricity error:', error.message);
    res.status(500).json({ error: error.message || 'Electricity payment failed' });
  }
};

// ─── POST /api/services/cable ────────────────────────────────────────────────
export const payCableTV = async (req: AuthRequest, res: Response) => {
  const { provider, smartCardNumber, variationCode, amount, phone } = req.body;
  const userId = req.user!.id;

  if (!provider || !smartCardNumber || !variationCode || !amount || !phone) {
    return res.status(400).json({ error: 'provider, smartCardNumber, variationCode, amount and phone are required' });
  }

  const serviceID = CABLE_SERVICE_IDS[provider];
  if (!serviceID) return res.status(400).json({ error: `Unknown provider: ${provider}` });

  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.balance < amount) return res.status(400).json({ error: 'Insufficient balance' });

    // Call VTPass
    const { requestId } = await vtpassPayCableTV(serviceID, smartCardNumber, variationCode, amount, phone);

    // Deduct & log
    const result = await recordTransaction(
      userId, amount, 'CABLE_TV', requestId, phone, provider,
      `₦${amount} ${provider} subscription for card ${smartCardNumber}`
    );

    res.json({ success: true, balance: result[0].balance, transaction: result[1] });
  } catch (error: any) {
    console.error('payCableTV error:', error.message);
    res.status(500).json({ error: error.message || 'Cable TV payment failed' });
  }
};

// ─── POST /api/services/transact (legacy — kept for FUND / CONVERT_AIRTIME) ──
export const transact = async (req: AuthRequest, res: Response) => {
  const { amount, type } = req.body;
  const userId = req.user!.id;

  try {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    const isCredit = type === 'CONVERT_AIRTIME' || type === 'FUND';
    const isDebit  = type === 'WITHDRAW';
    if (!isCredit && !isDebit) {
      return res.status(400).json({ error: `Invalid transaction type: ${type}` });
    }

    // Balance check for all debit operations
    if ((isDebit || !isCredit) && user.balance < amount)
      return res.status(400).json({ error: 'Insufficient balance' });

    const result = await prisma.$transaction([
      prisma.user.update({
        where: { id: userId },
        data: { balance: isCredit ? { increment: amount } : { decrement: amount } },
      }),
      prisma.transaction.create({
        data: { userId, amount, type, status: 'COMPLETED', reference: null },
      }),
      prisma.notification.create({
        data: {
          userId,
          title: isDebit ? 'Withdrawal Successful' : 'Transaction Successful',
          message: isDebit
            ? `₦${amount} withdrawal to your bank account was successful.`
            : `Your transaction of ₦${amount} for ${type} was successful.`,
        },
      }),
    ]);

    res.json({ success: true, balance: result[0].balance, transaction: result[1] });
  } catch (error) {
    res.status(500).json({ error: 'Transaction failed' });
  }
};

// ─── POST /api/services/convert-airtime ──────────────────────────────────────
export const convertAirtime = async (req: AuthRequest, res: Response) => {
  const { amount, network, phone } = req.body;
  const userId = req.user!.id;

  if (!amount || !network || !phone) {
    return res.status(400).json({ error: 'amount, network, and phone are required' });
  }

  try {
    const result = await AirtimeCashService.initializeConversion(amount, network, phone, userId);
    res.json(result);
  } catch (error: any) {
    console.error('convertAirtime error:', error.message);
    res.status(500).json({ error: error.message || 'Failed to initialize conversion' });
  }
};

// ─── POST /api/webhooks/airtime ──────────────────────────────────────────────
export const handleAirtimeWebhook = async (req: AuthRequest, res: Response) => {
  try {
    const result = await AirtimeCashService.handleWebhook(req.body);
    if (result.success) {
      res.json({ success: true });
    } else {
      res.status(400).json({ success: false, message: result.message });
    }
  } catch (error: any) {
    console.error('Webhook error:', error.message);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
};
