"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteBankAccount = exports.getBankAccounts = exports.addBankAccount = void 0;
const prisma_1 = require("../prisma");
const paystack_service_1 = require("../services/paystack.service");
const addBankAccount = async (req, res) => {
    const userId = req.user.id;
    const { accountNumber, bankCode, bankName } = req.body;
    if (!accountNumber || !bankCode || !bankName) {
        return res.status(400).json({ error: 'Missing required bank details' });
    }
    try {
        // 1. Verify account number via Paystack
        const accountName = await (0, paystack_service_1.verifyAccountNumber)(accountNumber, bankCode);
        // 2. Create Transfer Recipient via Paystack
        const recipientCode = await (0, paystack_service_1.createTransferRecipient)(accountName, accountNumber, bankCode);
        // 3. Save to database
        const bankAccount = await prisma_1.prisma.bankAccount.create({
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
    }
    catch (error) {
        res.status(400).json({ error: error.message || 'Failed to add bank account' });
    }
};
exports.addBankAccount = addBankAccount;
const getBankAccounts = async (req, res) => {
    const userId = req.user.id;
    try {
        const accounts = await prisma_1.prisma.bankAccount.findMany({
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
    }
    catch (error) {
        res.status(500).json({ error: error.message || 'Failed to fetch bank accounts' });
    }
};
exports.getBankAccounts = getBankAccounts;
const deleteBankAccount = async (req, res) => {
    const userId = req.user.id;
    const { id } = req.params;
    try {
        await prisma_1.prisma.bankAccount.deleteMany({
            where: { id, userId },
        });
        res.json({ success: true });
    }
    catch (error) {
        res.status(500).json({ error: error.message || 'Failed to delete bank account' });
    }
};
exports.deleteBankAccount = deleteBankAccount;
//# sourceMappingURL=bank.controller.js.map