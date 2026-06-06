"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleWebhook = exports.getVirtualAccount = void 0;
const prisma_1 = require("../prisma");
const paystack_service_1 = require("../services/paystack.service");
// ─── GET /api/wallet/virtual-account ─────────────────────────────────────────
// Returns (or provisions) the user's dedicated virtual account
const getVirtualAccount = async (req, res) => {
    const userId = req.user.id;
    try {
        const user = await prisma_1.prisma.user.findUnique({ where: { id: userId } });
        if (!user)
            return res.status(404).json({ error: 'User not found' });
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
            const lastName = nameParts.slice(1).join(' ') || firstName;
            const customer = await (0, paystack_service_1.createCustomer)(user.email, firstName, lastName, user.phone || undefined);
            customerCode = customer.customerCode;
        }
        // Try fetching an existing DVA for this customer first
        let dva = await (0, paystack_service_1.fetchDVA)(customerCode);
        // If none exists yet, create one
        if (!dva) {
            const nameParts = (user.fullName || user.email).split(' ');
            const firstName = nameParts[0] ?? 'User';
            const lastName = nameParts.slice(1).join(' ') || '';
            const fullName = lastName ? `${firstName} ${lastName}` : firstName;
            dva = await (0, paystack_service_1.createDVA)(customerCode, fullName);
        }
        // Persist to DB
        await prisma_1.prisma.user.update({
            where: { id: userId },
            data: {
                paystackCustomerCode: customerCode,
                virtualAccountNumber: dva.accountNumber,
                virtualAccountBank: dva.bankName,
                virtualAccountName: dva.accountName,
            },
        });
        return res.json({
            accountNumber: dva.accountNumber,
            bankName: dva.bankName,
            accountName: dva.accountName,
        });
    }
    catch (error) {
        console.error('getVirtualAccount error:', error.message);
        res.status(500).json({ error: error.message || 'Failed to get virtual account' });
    }
};
exports.getVirtualAccount = getVirtualAccount;
// ─── POST /api/wallet/webhook ─────────────────────────────────────────────────
// Paystack calls this when a transfer/charge succeeds on a DVA
const handleWebhook = async (req, res) => {
    // Always respond 200 immediately so Paystack doesn't retry
    res.sendStatus(200);
    const signature = req.headers['x-paystack-signature'] ?? '';
    const rawBody = JSON.stringify(req.body);
    // Reject invalid signatures
    if (!(0, paystack_service_1.verifyWebhookSignature)(rawBody, signature)) {
        console.warn('[Webhook] Invalid Paystack signature — ignored');
        return;
    }
    const event = req.body;
    // Only handle successful dedicated-account charges
    if (event.event !== 'charge.success')
        return;
    if (event.data?.channel !== 'dedicated_nuban')
        return;
    const customerCode = event.data?.customer?.customer_code;
    const amountKobo = event.data?.amount; // Paystack sends kobo
    const paystackRef = event.data?.reference;
    if (!customerCode || !amountKobo || !paystackRef) {
        console.warn('[Webhook] Missing fields in charge.success payload');
        return;
    }
    const amountNaira = amountKobo / 100;
    try {
        const user = await prisma_1.prisma.user.findFirst({
            where: { paystackCustomerCode: customerCode },
        });
        if (!user) {
            console.warn(`[Webhook] No user found for customerCode: ${customerCode}`);
            return;
        }
        // Guard against duplicate webhook delivery
        const existing = await prisma_1.prisma.transaction.findFirst({
            where: { reference: paystackRef },
        });
        if (existing) {
            console.log(`[Webhook] Duplicate webhook for ref ${paystackRef} — skipped`);
            return;
        }
        // Credit wallet atomically
        await prisma_1.prisma.$transaction([
            prisma_1.prisma.user.update({
                where: { id: user.id },
                data: { balance: { increment: amountNaira } },
            }),
            prisma_1.prisma.transaction.create({
                data: {
                    userId: user.id,
                    amount: amountNaira,
                    type: 'FUND',
                    status: 'COMPLETED',
                    reference: paystackRef,
                },
            }),
            prisma_1.prisma.notification.create({
                data: {
                    userId: user.id,
                    title: 'Wallet Funded',
                    message: `₦${amountNaira.toLocaleString()} has been added to your wallet.`,
                },
            }),
        ]);
        console.log(`[Webhook] ✅ Credited ₦${amountNaira} to user ${user.email}`);
    }
    catch (error) {
        console.error('[Webhook] Error processing payment:', error.message);
    }
};
exports.handleWebhook = handleWebhook;
//# sourceMappingURL=wallet.controller.js.map