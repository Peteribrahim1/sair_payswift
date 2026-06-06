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
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteAdvert = exports.createAdvert = exports.getAdminAdverts = exports.broadcastNotification = exports.rejectKyc = exports.approveKyc = exports.getPendingKyc = exports.manuallyFundUser = exports.updateSystemSettings = exports.getSystemSettings = exports.rejectAirtime = exports.approveAirtime = exports.getPendingAirtime = exports.resolveAdminTicket = exports.getAdminTickets = exports.getAdminTransactions = exports.getAdminUsers = void 0;
const prisma_1 = require("../prisma");
const admin = __importStar(require("firebase-admin"));
// Simple middleware/helper to check admin passcode header
const verifyAdminPasscode = (req) => {
    return req.headers['x-admin-secret'] === 'sair-sandbox-test-2026';
};
const getAdminUsers = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const users = await prisma_1.prisma.user.findMany({
            orderBy: { createdAt: 'desc' },
            select: {
                id: true,
                email: true,
                fullName: true,
                phone: true,
                balance: true,
                kycVerified: true,
                createdAt: true,
            }
        });
        res.json({ success: true, users });
    }
    catch (error) {
        console.error('getAdminUsers error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};
exports.getAdminUsers = getAdminUsers;
const getAdminTransactions = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const transactions = await prisma_1.prisma.transaction.findMany({
            orderBy: { createdAt: 'desc' },
            include: {
                user: {
                    select: {
                        email: true,
                        fullName: true,
                    }
                }
            }
        });
        res.json({ success: true, transactions });
    }
    catch (error) {
        console.error('getAdminTransactions error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};
exports.getAdminTransactions = getAdminTransactions;
const getAdminTickets = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const tickets = await prisma_1.prisma.ticket.findMany({
            orderBy: { createdAt: 'desc' },
            include: {
                user: {
                    select: {
                        email: true,
                        fullName: true,
                        phone: true,
                    }
                }
            }
        });
        res.json({ success: true, tickets });
    }
    catch (error) {
        console.error('getAdminTickets error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};
exports.getAdminTickets = getAdminTickets;
const resolveAdminTicket = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const { id } = req.params;
        const ticket = await prisma_1.prisma.ticket.update({
            where: { id },
            data: { status: 'RESOLVED' }
        });
        // Also trigger an automatic user notification that the issue was resolved
        await prisma_1.prisma.notification.create({
            data: {
                userId: ticket.userId,
                title: 'Support Issue Resolved',
                message: `Your support ticket regarding "${ticket.subject}" has been marked as resolved by our support staff.`
            }
        });
        res.json({ success: true, ticket });
    }
    catch (error) {
        console.error('resolveAdminTicket error:', error);
        res.status(500).json({ error: 'Internal server error.' });
    }
};
exports.resolveAdminTicket = resolveAdminTicket;
// ─── AIRTIME TO CASH APPROVALS ────────────────────────────────────────────────
const getPendingAirtime = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const transactions = await prisma_1.prisma.transaction.findMany({
            where: { type: 'CONVERT_AIRTIME', status: 'PENDING' },
            include: { user: { select: { fullName: true, email: true, phone: true } } },
            orderBy: { createdAt: 'desc' }
        });
        res.json({ success: true, transactions });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to fetch airtime transactions' });
    }
};
exports.getPendingAirtime = getPendingAirtime;
const approveAirtime = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
        const transaction = await prisma_1.prisma.transaction.findUnique({ where: { id } });
        if (!transaction || transaction.status !== 'PENDING') {
            return res.status(400).json({ error: 'Transaction not pending or not found' });
        }
        await prisma_1.prisma.$transaction([
            prisma_1.prisma.transaction.update({
                where: { id },
                data: { status: 'COMPLETED' }
            }),
            prisma_1.prisma.user.update({
                where: { id: transaction.userId },
                data: { balance: { increment: transaction.amount } }
            }),
            prisma_1.prisma.notification.create({
                data: {
                    userId: transaction.userId,
                    title: 'Airtime Converted',
                    message: `Your airtime to cash conversion of ₦${transaction.amount} was approved and credited.`
                }
            })
        ]);
        res.json({ success: true, message: 'Approved and credited.' });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to approve airtime' });
    }
};
exports.approveAirtime = approveAirtime;
const rejectAirtime = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
        const transaction = await prisma_1.prisma.transaction.findUnique({ where: { id } });
        if (!transaction || transaction.status !== 'PENDING') {
            return res.status(400).json({ error: 'Transaction not pending or not found' });
        }
        await prisma_1.prisma.$transaction([
            prisma_1.prisma.transaction.update({
                where: { id },
                data: { status: 'FAILED' }
            }),
            prisma_1.prisma.notification.create({
                data: {
                    userId: transaction.userId,
                    title: 'Airtime Conversion Failed',
                    message: `Your airtime to cash conversion of ₦${transaction.amount} was rejected.`
                }
            })
        ]);
        res.json({ success: true, message: 'Rejected.' });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to reject airtime' });
    }
};
exports.rejectAirtime = rejectAirtime;
// ─── SYSTEM SETTINGS & PRICING ────────────────────────────────────────────────
const getSystemSettings = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        let config = await prisma_1.prisma.appConfig.findUnique({ where: { id: 'global-config' } });
        if (!config) {
            config = await prisma_1.prisma.appConfig.create({
                data: {
                    id: 'global-config',
                    dataMarkupPercent: 5.0,
                    airtimeMarkupPercent: 2.0,
                    airtimeToCashRate: 70.0,
                    billConvenienceFee: 50.0
                }
            });
        }
        res.json({ success: true, settings: config });
    }
    catch (error) {
        console.error('getSystemSettings error:', error);
        res.status(500).json({ error: 'Failed to fetch settings' });
    }
};
exports.getSystemSettings = getSystemSettings;
const updateSystemSettings = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const { dataMarkupPercent, airtimeMarkupPercent, airtimeToCashRate, billConvenienceFee } = req.body;
        const config = await prisma_1.prisma.appConfig.upsert({
            where: { id: 'global-config' },
            update: {
                dataMarkupPercent: Number(dataMarkupPercent),
                airtimeMarkupPercent: Number(airtimeMarkupPercent),
                airtimeToCashRate: Number(airtimeToCashRate),
                billConvenienceFee: Number(billConvenienceFee)
            },
            create: {
                id: 'global-config',
                dataMarkupPercent: Number(dataMarkupPercent),
                airtimeMarkupPercent: Number(airtimeMarkupPercent),
                airtimeToCashRate: Number(airtimeToCashRate),
                billConvenienceFee: Number(billConvenienceFee)
            }
        });
        res.json({ success: true, settings: config, message: 'Settings updated successfully' });
    }
    catch (error) {
        console.error('updateSystemSettings error:', error);
        res.status(500).json({ error: 'Failed to update settings' });
    }
};
exports.updateSystemSettings = updateSystemSettings;
const manuallyFundUser = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    const { amount, action, reason } = req.body;
    if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
    }
    if (action !== 'CREDIT' && action !== 'DEBIT') {
        return res.status(400).json({ error: 'Invalid action. Must be CREDIT or DEBIT.' });
    }
    try {
        const user = await prisma_1.prisma.user.findUnique({ where: { id } });
        if (!user)
            return res.status(404).json({ error: 'User not found' });
        const adjustment = action === 'CREDIT' ? Number(amount) : -Number(amount);
        if (action === 'DEBIT' && user.balance < Number(amount)) {
            return res.status(400).json({ error: `Cannot debit ₦${amount}. User only has ₦${user.balance}.` });
        }
        const result = await prisma_1.prisma.$transaction([
            prisma_1.prisma.user.update({
                where: { id },
                data: { balance: { increment: adjustment } }
            }),
            prisma_1.prisma.transaction.create({
                data: {
                    userId: id,
                    amount: Number(amount),
                    type: action === 'CREDIT' ? 'FUND' : 'WITHDRAW',
                    reference: `ADMIN_${action}_${Date.now()}`,
                    status: 'SUCCESS',
                    details: reason || `Manual Admin ${action}`,
                }
            })
        ]);
        res.json({ success: true, user: result[0], transaction: result[1] });
    }
    catch (error) {
        console.error('manuallyFundUser error:', error);
        res.status(500).json({ error: 'Failed to manually adjust user balance' });
    }
};
exports.manuallyFundUser = manuallyFundUser;
const getPendingKyc = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const users = await prisma_1.prisma.user.findMany({
            where: { kycStatus: 'PENDING' },
            select: {
                id: true,
                fullName: true,
                email: true,
                bvn: true,
                nin: true,
                kycDocument: true,
                kycStatus: true,
                createdAt: true,
            },
            orderBy: { createdAt: 'desc' }
        });
        res.json({ success: true, users });
    }
    catch (error) {
        console.error('getPendingKyc error:', error);
        res.status(500).json({ error: 'Failed to fetch pending KYC' });
    }
};
exports.getPendingKyc = getPendingKyc;
const approveKyc = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
        const user = await prisma_1.prisma.user.update({
            where: { id },
            data: { kycStatus: 'VERIFIED', kycVerified: true }
        });
        res.json({ success: true, user });
    }
    catch (error) {
        console.error('approveKyc error:', error);
        res.status(500).json({ error: 'Failed to approve KYC' });
    }
};
exports.approveKyc = approveKyc;
const rejectKyc = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
        const user = await prisma_1.prisma.user.update({
            where: { id },
            data: { kycStatus: 'REJECTED', kycVerified: false, kycDocument: null }
        });
        // Optional: delete the file from disk using fs.unlinkSync if you want.
        res.json({ success: true, user });
    }
    catch (error) {
        console.error('rejectKyc error:', error);
        res.status(500).json({ error: 'Failed to reject KYC' });
    }
};
exports.rejectKyc = rejectKyc;
const index_1 = require("../index");
const broadcastNotification = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    const { title, message } = req.body;
    if (!title || !message) {
        return res.status(400).json({ error: 'Title and message are required' });
    }
    try {
        const users = await prisma_1.prisma.user.findMany({ select: { id: true, fcmToken: true } });
        if (users.length === 0) {
            return res.json({ success: true, message: 'No users found to broadcast to.' });
        }
        const notifications = users.map(u => ({
            userId: u.id,
            title,
            message,
        }));
        await prisma_1.prisma.notification.createMany({
            data: notifications,
        });
        // Send FCM push notifications to all users who have an fcmToken
        const tokens = users.map(u => u.fcmToken).filter(token => token !== null);
        let pushResultMsg = '';
        if (tokens.length > 0) {
            try {
                if (admin.apps.length === 0) {
                    throw new Error(`Firebase not initialized. Init Error: ${index_1.firebaseInitError?.message || index_1.firebaseInitError || 'Unknown'}`);
                }
                const response = await admin.messaging().sendEachForMulticast({
                    tokens,
                    notification: { title, body: message }
                });
                pushResultMsg = ` Also sent push notifications (Success: ${response.successCount}, Failed: ${response.failureCount}).`;
            }
            catch (fcmErr) {
                console.error('FCM Multicast error:', fcmErr.message);
                pushResultMsg = ` But failed to send push notifications: ${fcmErr.message}`;
            }
        }
        res.json({ success: true, message: `Broadcast saved to ${users.length} inboxes.${pushResultMsg}` });
    }
    catch (error) {
        console.error('broadcastNotification error:', error.message);
        res.status(500).json({ error: 'Failed to send broadcast.' });
    }
};
exports.broadcastNotification = broadcastNotification;
// ─── Advert Management ────────────────────────────────────────────────────────
const getAdminAdverts = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    try {
        const adverts = await prisma_1.prisma.advert.findMany({
            orderBy: { createdAt: 'desc' }
        });
        res.json({ success: true, adverts });
    }
    catch (error) {
        console.error('getAdminAdverts error:', error);
        res.status(500).json({ error: 'Failed to fetch adverts' });
    }
};
exports.getAdminAdverts = getAdminAdverts;
const createAdvert = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    const { title, imageBase64, contactLink, isActive } = req.body;
    if (!title || !imageBase64 || !contactLink) {
        return res.status(400).json({ error: 'Missing required advert fields' });
    }
    try {
        const advert = await prisma_1.prisma.advert.create({
            data: {
                title,
                imageBase64,
                contactLink,
                isActive: isActive !== undefined ? isActive : true,
            }
        });
        res.json({ success: true, advert });
    }
    catch (error) {
        console.error('createAdvert error:', error);
        res.status(500).json({ error: 'Failed to create advert' });
    }
};
exports.createAdvert = createAdvert;
const deleteAdvert = async (req, res) => {
    if (!verifyAdminPasscode(req))
        return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
        await prisma_1.prisma.advert.delete({ where: { id } });
        res.json({ success: true, message: 'Advert deleted successfully' });
    }
    catch (error) {
        console.error('deleteAdvert error:', error);
        res.status(500).json({ error: 'Failed to delete advert' });
    }
};
exports.deleteAdvert = deleteAdvert;
//# sourceMappingURL=admin.controller.js.map