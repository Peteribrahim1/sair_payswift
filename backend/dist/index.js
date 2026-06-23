"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.firebaseInitError = void 0;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
// ─── Startup Safety Checks ────────────────────────────────────────────────────
if (!process.env.JWT_SECRET) {
    console.error('❌ FATAL: JWT_SECRET environment variable is not set. Refusing to start.');
    process.exit(1);
}
const admin = __importStar(require("firebase-admin"));
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
exports.firebaseInitError = null;
// Initialize Firebase Admin
try {
    let credential;
    const localServiceAccountPath = path_1.default.resolve(__dirname, '../firebase-service-account.json');
    const renderSecretFilePath = '/etc/secrets/firebase-service-account.json';
    if (fs_1.default.existsSync(localServiceAccountPath)) {
        credential = admin.credential.cert(require(localServiceAccountPath));
    }
    else if (fs_1.default.existsSync(renderSecretFilePath)) {
        credential = admin.credential.cert(require(renderSecretFilePath));
    }
    else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        try {
            credential = admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT));
        }
        catch (e) {
            throw new Error(`JSON parse failed for FIREBASE_SERVICE_ACCOUNT: ${e}`);
        }
    }
    else {
        throw new Error("Missing Firebase service account credentials.");
    }
    admin.initializeApp({ credential });
    console.log('✅ Firebase Admin initialized');
}
catch (error) {
    exports.firebaseInitError = error;
    console.error('❌ Failed to initialize Firebase Admin:', error);
}
const auth_controller_1 = require("./controllers/auth.controller");
const user_controller_1 = require("./controllers/user.controller");
const services_controller_1 = require("./controllers/services.controller");
const notification_controller_1 = require("./controllers/notification.controller");
const wallet_controller_1 = require("./controllers/wallet.controller");
const auth_middleware_1 = require("./middleware/auth.middleware");
const prisma_1 = require("./prisma");
const support_controller_1 = require("./controllers/support.controller");
const admin_controller_1 = require("./controllers/admin.controller");
const app = (0, express_1.default)();
app.use((0, cors_1.default)());
app.use(express_1.default.json({ limit: '10mb' }));
// ─── Rate Limiting ────────────────────────────────────────────────────────────
// Auth endpoints: max 10 requests per 15 minutes per IP
const authLimiter = (0, express_rate_limit_1.default)({
    windowMs: 15 * 60 * 1000,
    max: 10,
    message: { error: 'Too many requests from this IP, please try again after 15 minutes.' },
    standardHeaders: true,
    legacyHeaders: false,
});
// Purchase endpoints: max 30 requests per minute per IP
const purchaseLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 1000,
    max: 30,
    message: { error: 'Too many purchase requests. Please slow down.' },
    standardHeaders: true,
    legacyHeaders: false,
});
// General API limiter: max 200 requests per minute
const generalLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 1000,
    max: 200,
    standardHeaders: true,
    legacyHeaders: false,
});
app.use('/api/', generalLimiter);
// Ensure uploads and public folders exist
const uploadsDir = path_1.default.join(__dirname, '../uploads');
if (!fs_1.default.existsSync(uploadsDir)) {
    fs_1.default.mkdirSync(uploadsDir, { recursive: true });
}
app.use('/uploads', express_1.default.static(uploadsDir));
// Serve static web pages from public folder
const publicDir = path_1.default.join(__dirname, '../public');
if (!fs_1.default.existsSync(publicDir)) {
    fs_1.default.mkdirSync(publicDir, { recursive: true });
}
app.use(express_1.default.static(publicDir));
// Serve admin dashboard at /admin route
app.get('/admin', (req, res) => {
    res.sendFile(path_1.default.join(__dirname, '../public/admin/index.html'));
});
// ─── Auth Routes ─────────────────────────────────────────────────────────────
app.post('/api/auth/register', authLimiter, auth_controller_1.register);
app.post('/api/auth/login', authLimiter, auth_controller_1.login);
app.post('/api/auth/forgot-password', authLimiter, auth_controller_1.forgotPassword);
app.post('/api/auth/verify-reset-otp', authLimiter, auth_controller_1.verifyResetOtp);
app.post('/api/auth/reset-password', authLimiter, auth_controller_1.resetPassword);
// ─── User Routes ─────────────────────────────────────────────────────────────
app.get('/api/user/profile', auth_middleware_1.authenticate, user_controller_1.getProfile);
app.put('/api/user/profile', auth_middleware_1.authenticate, user_controller_1.updateProfile);
app.post('/api/user/kyc', auth_middleware_1.authenticate, user_controller_1.submitKyc);
app.post('/api/user/kyc-document', auth_middleware_1.authenticate, express_1.default.json({ limit: '10mb' }), user_controller_1.uploadKycDocument);
app.post('/api/user/profile-picture', auth_middleware_1.authenticate, express_1.default.json({ limit: '10mb' }), user_controller_1.uploadProfilePicture);
app.post('/api/user/fcm-token', auth_middleware_1.authenticate, user_controller_1.saveFcmToken);
// ─── Service Routes (Real VTPass) ────────────────────────────────────────────
app.post('/api/services/airtime', auth_middleware_1.authenticate, purchaseLimiter, services_controller_1.buyAirtime);
app.post('/api/services/data', auth_middleware_1.authenticate, purchaseLimiter, services_controller_1.buyData);
app.post('/api/services/sme-data', auth_middleware_1.authenticate, purchaseLimiter, services_controller_1.buySmeData);
app.post('/api/services/electricity', auth_middleware_1.authenticate, purchaseLimiter, services_controller_1.payElectricity);
app.post('/api/services/cable', auth_middleware_1.authenticate, purchaseLimiter, services_controller_1.payCableTV);
app.post('/api/services/convert-airtime', auth_middleware_1.authenticate, purchaseLimiter, services_controller_1.convertAirtime);
// Variation / plan fetching (GET)
app.get('/api/services/data-plans/:network', auth_middleware_1.authenticate, services_controller_1.getDataPlans);
app.get('/api/services/sme-data-plans/:network', auth_middleware_1.authenticate, services_controller_1.getSmePlans);
app.get('/api/services/cable-plans/:provider', auth_middleware_1.authenticate, services_controller_1.getCablePlans);
// Smart card / Meter verification
app.post('/api/services/verify-smartcard', auth_middleware_1.authenticate, services_controller_1.verifySmartCard);
app.post('/api/services/verify-meter', auth_middleware_1.authenticate, services_controller_1.verifyMeter);
// ─── Wallet / DVA Routes ─────────────────────────────────────────────────────
app.get('/api/wallet/virtual-account', auth_middleware_1.authenticate, wallet_controller_1.getVirtualAccount);
app.post('/api/wallet/webhook', express_1.default.raw({ type: 'application/json' }), wallet_controller_1.handleWebhook);
app.post('/api/webhooks/airtime', express_1.default.json(), express_1.default.urlencoded({ extended: true }), services_controller_1.handleAirtimeWebhook);
// ─── Legacy: FUND / CONVERT_AIRTIME — race-condition patched ─────────────────
// WITHDRAW type has been removed. FUND and CONVERT_AIRTIME are credit-only.
app.post('/api/services/transact', auth_middleware_1.authenticate, services_controller_1.transact);
// ─── Notification Routes ─────────────────────────────────────────────────────
app.get('/api/notifications', auth_middleware_1.authenticate, notification_controller_1.getNotifications);
app.put('/api/notifications/:id/read', auth_middleware_1.authenticate, notification_controller_1.markNotificationRead);
// ─── Transactions Routes ─────────────────────────────────────────────────────
const transactions_controller_1 = require("./controllers/transactions.controller");
app.post('/api/transactions/withdraw', auth_middleware_1.authenticate, transactions_controller_1.withdrawFunds);
// ─── Bank Accounts ───────────────────────────────────────────────────────────
const bank_controller_1 = require("./controllers/bank.controller");
app.post('/api/user/bank-accounts', auth_middleware_1.authenticate, bank_controller_1.addBankAccount);
app.get('/api/user/bank-accounts', auth_middleware_1.authenticate, bank_controller_1.getBankAccounts);
app.delete('/api/user/bank-accounts/:id', auth_middleware_1.authenticate, bank_controller_1.deleteBankAccount);
// ─── TEMP: Add test credits for sandbox testing ───────────────────────────────
app.post('/api/admin/add-test-credits', async (req, res) => {
    if (req.headers['x-admin-secret'] !== 'sair-sandbox-test-2026')
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const user = await prisma_1.prisma.user.findFirst({ where: { email: 'peteribrahim@gmail.com' } });
        if (!user)
            return res.status(404).json({ error: 'User not found' });
        const saved = user.balance;
        await prisma_1.prisma.user.update({ where: { id: user.id }, data: { balance: saved + 10000 } });
        return res.json({ success: true, previousBalance: saved, newBalance: saved + 10000 });
    }
    catch (e) {
        return res.status(500).json({ error: e.message });
    }
});
app.post('/api/admin/restore-balance', async (req, res) => {
    if (req.headers['x-admin-secret'] !== 'sair-sandbox-test-2026')
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const user = await prisma_1.prisma.user.findFirst({ where: { email: 'peteribrahim@gmail.com' } });
        if (!user)
            return res.status(404).json({ error: 'User not found' });
        await prisma_1.prisma.user.update({ where: { id: user.id }, data: { balance: 50 } });
        return res.json({ success: true, restoredBalance: 50 });
    }
    catch (e) {
        return res.status(500).json({ error: e.message });
    }
});
app.get('/api/admin/recent-transactions', async (req, res) => {
    if (req.headers['x-admin-secret'] !== 'sair-sandbox-test-2026')
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const user = await prisma_1.prisma.user.findFirst({ where: { email: 'peteribrahim@gmail.com' } });
        if (!user)
            return res.status(404).json({ error: 'User not found' });
        const txs = await prisma_1.prisma.transaction.findMany({
            where: { userId: user.id },
            orderBy: { createdAt: 'desc' },
            take: 10,
            select: { type: true, amount: true, reference: true, status: true, createdAt: true },
        });
        return res.json({ success: true, transactions: txs });
    }
    catch (e) {
        return res.status(500).json({ error: e.message });
    }
});
// ─── Real Support Ticket & Admin Portal API Routes ────────────────────────────
app.post('/api/support/ticket', auth_middleware_1.authenticate, support_controller_1.createTicket);
app.post('/api/support/ai-chat', auth_middleware_1.authenticate, support_controller_1.aiChat);
app.get('/api/admin/users', admin_controller_1.getAdminUsers);
app.get('/api/admin/transactions', admin_controller_1.getAdminTransactions);
app.get('/api/admin/tickets', admin_controller_1.getAdminTickets);
app.put('/api/admin/tickets/:id/resolve', admin_controller_1.resolveAdminTicket);
app.get('/api/admin/airtime', admin_controller_1.getPendingAirtime);
app.post('/api/admin/airtime/:id/approve', admin_controller_1.approveAirtime);
app.post('/api/admin/airtime/:id/reject', admin_controller_1.rejectAirtime);
app.get('/api/admin/settings', admin_controller_1.getSystemSettings);
app.put('/api/admin/settings', admin_controller_1.updateSystemSettings);
app.post('/api/admin/users/:id/fund', admin_controller_1.manuallyFundUser);
app.get('/api/admin/kyc', admin_controller_1.getPendingKyc);
app.post('/api/admin/kyc/:id/approve', admin_controller_1.approveKyc);
app.post('/api/admin/kyc/:id/reject', admin_controller_1.rejectKyc);
app.post('/api/admin/broadcast', express_1.default.json(), admin_controller_1.broadcastNotification);
app.get('/api/admin/adverts', admin_controller_1.getAdminAdverts);
app.post('/api/admin/adverts', admin_controller_1.createAdvert);
app.delete('/api/admin/adverts/:id', admin_controller_1.deleteAdvert);
// ─── Public Config/Advert Routes ──────────────────────────────────────────────
app.get('/api/adverts', services_controller_1.getActiveAdverts);
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT} [VTPass: ${process.env.VTPASS_ENV || 'sandbox'}]`);
});
//# sourceMappingURL=index.js.map