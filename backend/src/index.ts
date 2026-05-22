import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

import { register, login } from './controllers/auth.controller';
import { getProfile, updateProfile, submitKyc } from './controllers/user.controller';
import {
  transact,
  buyAirtime,
  buyData,
  payElectricity,
  payCableTV,
  getDataPlans,
  getCablePlans,
  verifySmartCard,
  verifyMeter,
} from './controllers/services.controller';
import { getNotifications, markNotificationRead } from './controllers/notification.controller';
import { getVirtualAccount, handleWebhook } from './controllers/wallet.controller';
import { authenticate } from './middleware/auth.middleware';
import { prisma } from './prisma';

const app = express();
app.use(cors());
app.use(express.json());

// ─── Auth Routes ─────────────────────────────────────────────────────────────
app.post('/api/auth/register', register);
app.post('/api/auth/login', login);

// ─── User Routes ─────────────────────────────────────────────────────────────
app.get('/api/user/profile', authenticate, getProfile);
app.put('/api/user/profile', authenticate, updateProfile);
app.post('/api/user/kyc', authenticate, submitKyc);

// ─── Service Routes (Real VTPass) ────────────────────────────────────────────
app.post('/api/services/airtime', authenticate, buyAirtime);
app.post('/api/services/data', authenticate, buyData);
app.post('/api/services/electricity', authenticate, payElectricity);
app.post('/api/services/cable', authenticate, payCableTV);

// Variation / plan fetching (GET)
app.get('/api/services/data-plans/:network', authenticate, getDataPlans);
app.get('/api/services/cable-plans/:provider', authenticate, getCablePlans);

// Smart card / Meter verification
app.post('/api/services/verify-smartcard', authenticate, verifySmartCard);
app.post('/api/services/verify-meter', authenticate, verifyMeter);

// ─── Wallet / DVA Routes ─────────────────────────────────────────────────────
app.get('/api/wallet/virtual-account', authenticate, getVirtualAccount);
app.post('/api/wallet/webhook', express.raw({ type: 'application/json' }), handleWebhook);

// ─── Legacy: FUND / CONVERT_AIRTIME ─────────────────────────────────────────
app.post('/api/services/transact', authenticate, transact);

// ─── Notification Routes ─────────────────────────────────────────────────────
app.get('/api/notifications', authenticate, getNotifications);
app.put('/api/notifications/:id/read', authenticate, markNotificationRead);

// ─── Transactions Routes ─────────────────────────────────────────────────────
import { withdrawFunds } from './controllers/transactions.controller';
app.post('/api/transactions/withdraw', authenticate, withdrawFunds);

// ─── Bank Accounts ───────────────────────────────────────────────────────────
import { addBankAccount, getBankAccounts, deleteBankAccount } from './controllers/bank.controller';
app.post('/api/user/bank-accounts', authenticate, addBankAccount);
app.get('/api/user/bank-accounts', authenticate, getBankAccounts);
app.delete('/api/user/bank-accounts/:id', authenticate, deleteBankAccount);

// ─── TEMP: Add test credits for sandbox testing ───────────────────────────────
app.post('/api/admin/add-test-credits', async (req: any, res: any) => {
  if (req.headers['x-admin-secret'] !== 'sair-sandbox-test-2026') return res.status(401).json({ error: 'Unauthorized' });
  try {
    const user = await prisma.user.findFirst({ where: { email: 'peteribrahim@gmail.com' } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    const saved = user.balance;
    await prisma.user.update({ where: { id: user.id }, data: { balance: saved + 10000 } });
    return res.json({ success: true, previousBalance: saved, newBalance: saved + 10000 });
  } catch (e: any) { return res.status(500).json({ error: e.message }); }
});

app.post('/api/admin/restore-balance', async (req: any, res: any) => {
  if (req.headers['x-admin-secret'] !== 'sair-sandbox-test-2026') return res.status(401).json({ error: 'Unauthorized' });
  try {
    const user = await prisma.user.findFirst({ where: { email: 'peteribrahim@gmail.com' } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    await prisma.user.update({ where: { id: user.id }, data: { balance: 50 } });
    return res.json({ success: true, restoredBalance: 50 });
  } catch (e: any) { return res.status(500).json({ error: e.message }); }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT} [VTPass: ${process.env.VTPASS_ENV || 'sandbox'}]`);
});

