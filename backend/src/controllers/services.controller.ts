import { Request, Response } from 'express';
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
import { smeplugGetDataPlans, smeplugBuyData, SMEPLUG_NETWORK_IDS } from '../services/smeplug.service';

// ─── Helper: Atomic Debit ──────────────────────────────────────────────────────
async function debitWalletAndCreateTx(userId: string, amount: number, type: string, reference: string, phone?: string, network?: string) {
  if (amount <= 0) throw new Error('Amount must be greater than zero');
  
  const result = await prisma.user.updateMany({
    where: { id: userId, balance: { gte: amount } },
    data: { balance: { decrement: amount } },
  });

  if (result.count === 0) {
    throw new Error(`Insufficient balance. Total charge is ₦${amount.toFixed(2)}`);
  }

  return prisma.transaction.create({
    data: { userId, amount, type, status: 'PENDING', reference, phone, network },
  });
}

// ─── Helper: Refund Wallet on Failure ─────────────────────────────────────────
async function refundWalletAndFailTx(userId: string, amount: number, txId: string) {
  await prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: { balance: { increment: amount } },
    }),
    prisma.transaction.update({
      where: { id: txId },
      data: { status: 'FAILED' },
    }),
  ]);
}

// ─── Helper: Complete Transaction & Notify ────────────────────────────────────
async function completeTransaction(userId: string, txId: string, title: string, message: string) {
  await prisma.$transaction([
    prisma.transaction.update({
      where: { id: txId },
      data: { status: 'COMPLETED' },
    }),
    prisma.notification.create({
      data: { userId, title, message },
    }),
  ]);
  
  // Return updated user balance
  return prisma.user.findUnique({ where: { id: userId }, select: { balance: true } });
}

// ─── GET /api/services/data-plans/:network ───────────────────────────────────
export const getDataPlans = async (req: AuthRequest, res: Response) => {
  const { network } = req.params;
  const serviceID = DATA_SERVICE_IDS[network];
  if (!serviceID) return res.status(400).json({ error: `Unknown network: ${network}` });

  try {
    const plans = await vtpassGetDataVariations(serviceID);
    
    // Apply dynamic markup
    let markup = 5.0;
    const config = await prisma.appConfig.findUnique({ where: { id: 'global-config' } });
    if (config) markup = config.dataMarkupPercent;

    const markedUpPlans = plans.map((p: any) => {
        const rawPrice = parseFloat(p.variation_amount);
      if (!isNaN(rawPrice)) {
         p.variation_amount = (rawPrice + (rawPrice * (markup / 100))).toString();
      }
      if (typeof p.name === 'string') {
        let n = p.name;
        n = n.replace(/\s*-\s*(?:N|₦)?[\d,.]+(?:\s*Naira)?\s*-\s*/i, ' - ');
        n = n.replace(/\s*-\s*(?:N|₦)?[\d,.]+(?:\s*Naira)?\s*$/i, '');
        p.name = n;
      }
      return p;
    });

    res.json({ plans: markedUpPlans });
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

  const faceValue = parseFloat(amount.toString());
  if (isNaN(faceValue) || faceValue <= 0) {
    return res.status(400).json({ error: 'Invalid amount' });
  }

  const serviceID = AIRTIME_SERVICE_IDS[network];
  if (!serviceID) return res.status(400).json({ error: `Unknown network: ${network}` });

  try {
    let markup = 2.0;
    const config = await prisma.appConfig.findUnique({ where: { id: 'global-config' } });
    if (config) markup = config.airtimeMarkupPercent;
    
    const totalCharge = faceValue + (faceValue * (markup / 100));

    // 1. Atomically debit the wallet
    const tx = await debitWalletAndCreateTx(userId, totalCharge, 'AIRTIME', `PENDING-${Date.now()}`, phone, network);

    try {
      // 2. Call VTPass
      const { requestId } = await vtpassBuyAirtime(serviceID, phone, faceValue);
      
      // 3. Complete and notify
      await prisma.transaction.update({ where: { id: tx.id }, data: { reference: requestId } }); // Update ref
      const user = await completeTransaction(userId, tx.id, 'Transaction Successful', `₦${faceValue} airtime sent to ${phone} (${network})`);
      
      res.json({ success: true, balance: user?.balance, transaction: { ...tx, status: 'COMPLETED', reference: requestId } });
    } catch (apiError: any) {
      // Refund if VTPass fails
      await refundWalletAndFailTx(userId, totalCharge, tx.id);
      throw new Error(apiError.message || 'Airtime purchase failed at provider');
    }
  } catch (error: any) {
    console.error('buyAirtime error:', error.message);
    res.status(500).json({ error: error.message || 'Airtime purchase failed' });
  }
};

// ─── POST /api/services/data ─────────────────────────────────────────────────
export const buyData = async (req: AuthRequest, res: Response) => {
  const { network, phone, variationCode } = req.body;
  const userId = req.user!.id;

  if (!network || !phone || !variationCode) {
    return res.status(400).json({ error: 'network, phone, variationCode are required' });
  }

  const serviceID = DATA_SERVICE_IDS[network];
  if (!serviceID) return res.status(400).json({ error: `Unknown network: ${network}` });

  try {
    // 1. Fetch raw variations to find the raw amount
    const plans = await vtpassGetDataVariations(serviceID);
    const plan = plans.find((p: any) => p.variation_code === variationCode);
    if (!plan) return res.status(400).json({ error: 'Invalid data plan selected' });
    
    const rawPrice = parseFloat(plan.variation_amount);
    if (isNaN(rawPrice) || rawPrice <= 0) return res.status(400).json({ error: 'Invalid data plan amount' });

    let markup = 5.0;
    const config = await prisma.appConfig.findUnique({ where: { id: 'global-config' } });
    if (config) markup = config.dataMarkupPercent;

    const totalCharge = rawPrice + (rawPrice * (markup / 100));

    // 2. Atomically debit the wallet
    const tx = await debitWalletAndCreateTx(userId, totalCharge, 'DATA', `PENDING-${Date.now()}`, phone, network);

    try {
      // 3. Call VTPass
      const { requestId } = await vtpassBuyData(serviceID, phone, variationCode, rawPrice);
      
      // 4. Complete and notify
      await prisma.transaction.update({ where: { id: tx.id }, data: { reference: requestId } });
      const user = await completeTransaction(userId, tx.id, 'Transaction Successful', `₦${rawPrice} data bundle sent to ${phone} (${network})`);
      
      res.json({ success: true, balance: user?.balance, transaction: { ...tx, status: 'COMPLETED', reference: requestId } });
    } catch (apiError: any) {
      // Refund if VTPass fails
      await refundWalletAndFailTx(userId, totalCharge, tx.id);
      throw new Error(apiError.message || 'Data purchase failed at provider');
    }
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

  const rawAmount = parseFloat(amount.toString());
  if (isNaN(rawAmount) || rawAmount <= 0) {
    return res.status(400).json({ error: 'Invalid amount' });
  }

  const serviceID = ELECTRICITY_SERVICE_IDS[provider];
  if (!serviceID) return res.status(400).json({ error: `Unknown provider: ${provider}` });

  const variationCode = meterType === 'prepaid' ? 'prepaid' : 'postpaid';

  try {
    let fee = 50.0;
    const config = await prisma.appConfig.findUnique({ where: { id: 'global-config' } });
    if (config) fee = config.billConvenienceFee;

    const totalCharge = rawAmount + fee;

    // 1. Atomically debit the wallet
    const tx = await debitWalletAndCreateTx(userId, totalCharge, 'ELECTRICITY', `PENDING-${Date.now()}`, phone, provider);

    try {
      // 2. Call VTPass
      const { requestId } = await vtpassPayElectricity(serviceID, meterNumber, variationCode, rawAmount, phone);
      
      // 3. Complete and notify
      await prisma.transaction.update({ where: { id: tx.id }, data: { reference: requestId } });
      const user = await completeTransaction(userId, tx.id, 'Transaction Successful', `₦${rawAmount} electricity payment for meter ${meterNumber} (${provider})`);
      
      res.json({ success: true, balance: user?.balance, transaction: { ...tx, status: 'COMPLETED', reference: requestId } });
    } catch (apiError: any) {
      // Refund if VTPass fails
      await refundWalletAndFailTx(userId, totalCharge, tx.id);
      throw new Error(apiError.message || 'Electricity payment failed at provider');
    }
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

  const rawAmount = parseFloat(amount.toString());
  if (isNaN(rawAmount) || rawAmount <= 0) {
    return res.status(400).json({ error: 'Invalid amount' });
  }

  const serviceID = CABLE_SERVICE_IDS[provider];
  if (!serviceID) return res.status(400).json({ error: `Unknown provider: ${provider}` });

  try {
    let fee = 50.0;
    const config = await prisma.appConfig.findUnique({ where: { id: 'global-config' } });
    if (config) fee = config.billConvenienceFee;

    const totalCharge = rawAmount + fee;

    // 1. Atomically debit the wallet
    const tx = await debitWalletAndCreateTx(userId, totalCharge, 'CABLE_TV', `PENDING-${Date.now()}`, phone, provider);

    try {
      // 2. Call VTPass
      const { requestId } = await vtpassPayCableTV(serviceID, smartCardNumber, variationCode, rawAmount, phone);
      
      // 3. Complete and notify
      await prisma.transaction.update({ where: { id: tx.id }, data: { reference: requestId } });
      const user = await completeTransaction(userId, tx.id, 'Transaction Successful', `₦${rawAmount} ${provider} subscription for card ${smartCardNumber}`);
      
      res.json({ success: true, balance: user?.balance, transaction: { ...tx, status: 'COMPLETED', reference: requestId } });
    } catch (apiError: any) {
      // Refund if VTPass fails
      await refundWalletAndFailTx(userId, totalCharge, tx.id);
      throw new Error(apiError.message || 'Cable TV payment failed at provider');
    }
  } catch (error: any) {
    console.error('payCableTV error:', error.message);
    res.status(500).json({ error: error.message || 'Cable TV payment failed' });
  }
};

// ─── POST /api/services/transact (legacy — FUND / CONVERT_AIRTIME credits only) ──
export const transact = async (req: AuthRequest, res: Response) => {
  const { amount, type } = req.body;
  const userId = req.user!.id;

  const parsedAmount = parseFloat(amount?.toString() || '0');
  if (isNaN(parsedAmount) || parsedAmount <= 0) {
    return res.status(400).json({ error: 'Invalid amount' });
  }

  // WITHDRAW is explicitly blocked here — use /api/transactions/withdraw instead
  const allowedTypes = ['CONVERT_AIRTIME', 'FUND'];
  if (!allowedTypes.includes(type)) {
    return res.status(400).json({ error: `Transaction type '${type}' is not allowed on this endpoint.` });
  }

  try {
    const result = await prisma.$transaction([
      prisma.user.update({
        where: { id: userId },
        data: { balance: { increment: parsedAmount } },
      }),
      prisma.transaction.create({
        data: { userId, amount: parsedAmount, type, status: 'COMPLETED', reference: null },
      }),
      prisma.notification.create({
        data: {
          userId,
          title: 'Transaction Successful',
          message: `Your transaction of ₦${parsedAmount} for ${type} was successful.`,
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

// ─── SMEPlug (SME Data Plans) ───────────────────────────────────────────────

export const getSmePlans = async (req: AuthRequest, res: Response) => {
  const { network } = req.params;
  
  const networkId = SMEPLUG_NETWORK_IDS[network];
  if (!networkId) return res.status(400).json({ error: `Unknown network: ${network}` });

  try {
    const plans = await smeplugGetDataPlans(networkId);
    
    // Add dynamic markup
    let markup = 5.0;
    const config = await prisma.appConfig.findUnique({ where: { id: 'global-config' } });
    if (config) markup = config.dataMarkupPercent;

    const formattedPlans = plans.map(p => {
      const rawPrice = parseFloat(p.price);
      let cleanName = p.name;
      cleanName = cleanName.replace(/\s*-\s*(?:N|₦)?[\d,.]+(?:\s*Naira)?\s*-\s*/i, ' - ');
      cleanName = cleanName.replace(/\s*-\s*(?:N|₦)?[\d,.]+(?:\s*Naira)?\s*$/i, '');

      return {
        id: p.id,
        network,
        name: cleanName,
        price: rawPrice + (rawPrice * (markup / 100)), // Apply markup
        raw_price: rawPrice,
      };
    });

    res.json({ success: true, plans: formattedPlans });
  } catch (error: any) {
    console.error('getSmePlans error:', error.message);
    res.status(500).json({ error: error.message || 'Failed to fetch SME plans' });
  }
};

export const buySmeData = async (req: AuthRequest, res: Response) => {
  const { network, phone, planId, rawPrice } = req.body;
  const userId = req.user!.id;

  if (!network || !phone || !planId || !rawPrice) {
    return res.status(400).json({ error: 'network, phone, planId, rawPrice are required' });
  }

  const networkId = SMEPLUG_NETWORK_IDS[network];
  if (!networkId) return res.status(400).json({ error: `Unknown network: ${network}` });

  const parsedRawPrice = parseFloat(rawPrice.toString());
  if (isNaN(parsedRawPrice) || parsedRawPrice <= 0) {
    return res.status(400).json({ error: 'Invalid raw price' });
  }

  try {
    // 1. Get dynamic markup
    let markup = 5.0;
    const config = await prisma.appConfig.findUnique({ where: { id: 'global-config' } });
    if (config) markup = config.dataMarkupPercent;

    const totalCharge = parsedRawPrice + (parsedRawPrice * (markup / 100));

    // 2. Atomically debit the wallet
    const tx = await debitWalletAndCreateTx(userId, totalCharge, 'DATA_SME', `PENDING-SME-${Date.now()}`, phone, network);

    try {
      // 3. Call SMEPlug API
      const { reference } = await smeplugBuyData(networkId, planId, phone, tx.reference!);
      
      // 4. Complete and notify
      await prisma.transaction.update({ where: { id: tx.id }, data: { reference: reference } });
      const user = await completeTransaction(userId, tx.id, 'Transaction Successful', `₦${totalCharge.toFixed(2)} SME data sent to ${phone} (${network})`);
      
      res.json({ success: true, balance: user?.balance, transaction: { ...tx, status: 'COMPLETED', reference: reference } });
    } catch (apiError: any) {
      // Refund if SMEPlug fails
      await refundWalletAndFailTx(userId, totalCharge, tx.id);
      
      let providerMsg = apiError.response?.data?.msg || apiError.response?.data?.message || apiError.message;
      if (apiError.response?.data?.errors) {
        providerMsg += ' | Details: ' + JSON.stringify(apiError.response.data.errors);
      }

      throw new Error(`SMEPlug Error: ${providerMsg} (Net: ${networkId}, Plan: ${planId})`);
    }
  } catch (error: any) {
    console.error('buySmeData error:', error.message);
    res.status(500).json({ error: error.message || 'SME Data purchase failed' });
  }
};

// ─── Adverts ────────────────────────────────────────────────────────────────
export const getActiveAdverts = async (req: Request, res: Response) => {
  try {
    const adverts = await prisma.advert.findMany({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, adverts });
  } catch (error) {
    console.error('Get adverts error:', error);
    res.status(500).json({ error: 'Failed to fetch adverts.' });
  }
};
