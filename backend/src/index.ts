import express from 'express';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

dotenv.config();

// ─── Startup Safety Checks ────────────────────────────────────────────────────
if (!process.env.JWT_SECRET) {
  console.error('❌ FATAL: JWT_SECRET environment variable is not set. Refusing to start.');
  process.exit(1);
}

import * as admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';

export let firebaseInitError: any = null;

// Initialize Firebase Admin
try {
  let credential;
  const localServiceAccountPath = path.resolve(__dirname, '../firebase-service-account.json');
  const renderSecretFilePath = '/etc/secrets/firebase-service-account.json';

  if (fs.existsSync(localServiceAccountPath)) {
    credential = admin.credential.cert(require(localServiceAccountPath));
  } else if (fs.existsSync(renderSecretFilePath)) {
    credential = admin.credential.cert(require(renderSecretFilePath));
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      credential = admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT));
    } catch (e) {
      throw new Error(`JSON parse failed for FIREBASE_SERVICE_ACCOUNT: ${e}`);
    }
  } else {
    throw new Error("Missing Firebase service account credentials.");
  }
  admin.initializeApp({ credential });
  console.log('✅ Firebase Admin initialized');
} catch (error) {
  firebaseInitError = error;
  console.error('❌ Failed to initialize Firebase Admin:', error);
}
import { register, login } from './controllers/auth.controller';
import { getProfile, updateProfile, submitKyc, uploadProfilePicture, uploadKycDocument, saveFcmToken } from './controllers/user.controller';
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
  convertAirtime,
  handleAirtimeWebhook,
  getSmePlans,
  buySmeData,
} from './controllers/services.controller';
import { getNotifications, markNotificationRead } from './controllers/notification.controller';
import { getVirtualAccount, handleWebhook } from './controllers/wallet.controller';
import { authenticate } from './middleware/auth.middleware';
import { authenticateAdmin } from './middleware/admin.middleware';
import { prisma } from './prisma';

import { createTicket, aiChat } from './controllers/support.controller';
import {
  getAdminUsers,
  getAdminTransactions,
  getAdminTickets,
  resolveAdminTicket,
  getPendingAirtime,
  approveAirtime,
  rejectAirtime,
  getSystemSettings,
  updateSystemSettings,
  manuallyFundUser,
  getPendingKyc,
  approveKyc,
  rejectKyc,
  broadcastNotification
} from './controllers/admin.controller';

const app = express();
app.use(cors());
app.use(express.json());

// ─── Rate Limiting ────────────────────────────────────────────────────────────
// Auth endpoints: max 10 requests per 15 minutes per IP
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { error: 'Too many requests from this IP, please try again after 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Purchase endpoints: max 30 requests per minute per IP
const purchaseLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 30,
  message: { error: 'Too many purchase requests. Please slow down.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// General API limiter: max 200 requests per minute
const generalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', generalLimiter);

// Ensure uploads and public folders exist
const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
app.use('/uploads', express.static(uploadsDir));

// Serve static web pages from public folder
const publicDir = path.join(__dirname, '../public');
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir, { recursive: true });
}
app.use(express.static(publicDir));

// Serve admin dashboard at /admin route
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/admin/index.html'));
});

// ─── Auth Routes ─────────────────────────────────────────────────────────────
app.post('/api/auth/register', authLimiter, register);
app.post('/api/auth/login', authLimiter, login);

// ─── User Routes ─────────────────────────────────────────────────────────────
app.get('/api/user/profile', authenticate, getProfile);
app.put('/api/user/profile', authenticate, updateProfile);
app.post('/api/user/kyc', authenticate, submitKyc);
app.post('/api/user/kyc-document', authenticate, express.json({ limit: '10mb' }), uploadKycDocument);
app.post('/api/user/profile-picture', authenticate, express.json({ limit: '10mb' }), uploadProfilePicture);
app.post('/api/user/fcm-token', authenticate, saveFcmToken);

// ─── Service Routes (Real VTPass) ────────────────────────────────────────────
app.post('/api/services/airtime', authenticate, purchaseLimiter, buyAirtime);
app.post('/api/services/data', authenticate, purchaseLimiter, buyData);
app.post('/api/services/sme-data', authenticate, purchaseLimiter, buySmeData);
app.post('/api/services/electricity', authenticate, purchaseLimiter, payElectricity);
app.post('/api/services/cable', authenticate, purchaseLimiter, payCableTV);
app.post('/api/services/convert-airtime', authenticate, purchaseLimiter, convertAirtime);

// Variation / plan fetching (GET)
app.get('/api/services/data-plans/:network', authenticate, getDataPlans);
app.get('/api/services/sme-data-plans/:network', authenticate, getSmePlans);
app.get('/api/services/cable-plans/:provider', authenticate, getCablePlans);

// Smart card / Meter verification
app.post('/api/services/verify-smartcard', authenticate, verifySmartCard);
app.post('/api/services/verify-meter', authenticate, verifyMeter);

// ─── Wallet / DVA Routes ─────────────────────────────────────────────────────
app.get('/api/wallet/virtual-account', authenticate, getVirtualAccount);
app.post('/api/wallet/webhook', express.raw({ type: 'application/json' }), handleWebhook);
app.post('/api/webhooks/airtime', express.json(), express.urlencoded({ extended: true }), handleAirtimeWebhook);

// ─── Legacy: FUND / CONVERT_AIRTIME — race-condition patched ─────────────────
// WITHDRAW type has been removed. FUND and CONVERT_AIRTIME are credit-only.
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

app.get('/api/admin/recent-transactions', async (req: any, res: any) => {
  if (req.headers['x-admin-secret'] !== 'sair-sandbox-test-2026') return res.status(401).json({ error: 'Unauthorized' });
  try {
    const user = await prisma.user.findFirst({ where: { email: 'peteribrahim@gmail.com' } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    const txs = await prisma.transaction.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
      take: 10,
      select: { type: true, amount: true, reference: true, status: true, createdAt: true },
    });
    return res.json({ success: true, transactions: txs });
  } catch (e: any) { return res.status(500).json({ error: e.message }); }
});

// ─── Real Support Ticket & Admin Portal API Routes ────────────────────────────
app.post('/api/support/ticket', authenticate, createTicket);
app.post('/api/support/ai-chat', authenticate, aiChat);
app.get('/api/admin/users', authenticateAdmin, getAdminUsers);
app.get('/api/admin/transactions', authenticateAdmin, getAdminTransactions);
app.get('/api/admin/tickets', authenticateAdmin, getAdminTickets);
app.put('/api/admin/tickets/:id/resolve', authenticateAdmin, resolveAdminTicket);
app.get('/api/admin/airtime', authenticateAdmin, getPendingAirtime);
app.post('/api/admin/airtime/:id/approve', authenticateAdmin, approveAirtime);
app.post('/api/admin/airtime/:id/reject', authenticateAdmin, rejectAirtime);
app.get('/api/admin/settings', authenticateAdmin, getSystemSettings);
app.put('/api/admin/settings', authenticateAdmin, updateSystemSettings);
app.post('/api/admin/users/:id/fund', authenticateAdmin, manuallyFundUser);
app.get('/api/admin/kyc', authenticateAdmin, getPendingKyc);
app.post('/api/admin/kyc/:id/approve', authenticateAdmin, approveKyc);
app.post('/api/admin/kyc/:id/reject', authenticateAdmin, rejectKyc);

app.post('/api/admin/broadcast', authenticateAdmin, express.json(), broadcastNotification);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT} [VTPass: ${process.env.VTPASS_ENV || 'sandbox'}]`);
});
