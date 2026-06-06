"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.withdrawFunds = void 0;
const prisma_1 = require("../prisma");
const paystack_service_1 = require("../services/paystack.service");
const crypto_1 = __importDefault(require("crypto"));
// ─── POST /api/transactions/withdraw ──────────────────────────────────────────
const withdrawFunds = async (req, res) => {
    const userId = req.user.id;
    const { amount, bankAccountId } = req.body;
    const rawAmount = parseFloat(amount?.toString() || '0');
    if (isNaN(rawAmount) || rawAmount <= 0) {
        return res.status(400).json({ error: 'Valid amount is required' });
    }
    if (!bankAccountId) {
        return res.status(400).json({ error: 'Bank account is required' });
    }
    try {
        const bankAccount = await prisma_1.prisma.bankAccount.findFirst({
            where: { id: bankAccountId, userId },
        });
        if (!bankAccount) {
            return res.status(404).json({ error: 'Bank account not found' });
        }
        // 1. Atomically debit wallet
        const debitResult = await prisma_1.prisma.user.updateMany({
            where: { id: userId, balance: { gte: rawAmount } },
            data: { balance: { decrement: rawAmount } },
        });
        if (debitResult.count === 0) {
            return res.status(400).json({ error: 'Insufficient wallet balance' });
        }
        const reference = crypto_1.default.randomBytes(16).toString('hex');
        const tx = await prisma_1.prisma.transaction.create({
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
            const transferResult = await (0, paystack_service_1.initiateTransfer)(rawAmount, bankAccount.recipientCode, reference);
            if (transferResult.status !== 'success' && transferResult.status !== 'pending') {
                throw new Error(`Transfer failed: ${transferResult.status}`);
            }
            // 3. Complete and notify
            await prisma_1.prisma.$transaction([
                prisma_1.prisma.transaction.update({
                    where: { id: tx.id },
                    data: { status: 'COMPLETED', reference: transferResult.reference || reference },
                }),
                prisma_1.prisma.notification.create({
                    data: {
                        userId,
                        title: 'Withdrawal Processed',
                        message: `Your withdrawal of ₦${rawAmount.toFixed(2)} to ${bankAccount.bankName} is being processed.`,
                    },
                }),
            ]);
            const updatedUser = await prisma_1.prisma.user.findUnique({
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
        }
        catch (apiError) {
            // Refund if Paystack initiation fails
            await prisma_1.prisma.$transaction([
                prisma_1.prisma.user.update({
                    where: { id: userId },
                    data: { balance: { increment: rawAmount } },
                }),
                prisma_1.prisma.transaction.update({
                    where: { id: tx.id },
                    data: { status: 'FAILED' },
                }),
            ]);
            throw new Error(apiError.message || 'Withdrawal failed at provider');
        }
    }
    catch (error) {
        console.error('Withdrawal error:', error);
        res.status(500).json({ error: error.message || 'Withdrawal failed' });
    }
};
exports.withdrawFunds = withdrawFunds;
//# sourceMappingURL=transactions.controller.js.map