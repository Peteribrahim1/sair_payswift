"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createCustomer = createCustomer;
exports.validateCustomerKYC = validateCustomerKYC;
exports.createDVA = createDVA;
exports.fetchDVA = fetchDVA;
exports.verifyWebhookSignature = verifyWebhookSignature;
exports.fetchBanks = fetchBanks;
exports.verifyAccountNumber = verifyAccountNumber;
exports.createTransferRecipient = createTransferRecipient;
exports.initiateTransfer = initiateTransfer;
const axios_1 = __importDefault(require("axios"));
const crypto_1 = __importDefault(require("crypto"));
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;
const BASE_URL = 'https://api.paystack.co';
const HEADERS = {
    Authorization: `Bearer ${SECRET_KEY}`,
    'Content-Type': 'application/json',
};
// ─── Create a Paystack Customer ───────────────────────────────────────────────
async function createCustomer(email, firstName, lastName, phone) {
    const { data } = await axios_1.default.post(`${BASE_URL}/customer`, {
        email,
        first_name: firstName,
        last_name: lastName,
        phone: phone
    }, { headers: HEADERS });
    if (!data.status)
        throw new Error(data.message || 'Failed to create Paystack customer');
    return { customerCode: data.data.customer_code };
}
// ─── Validate Paystack Customer (KYC) ─────────────────────────────────────────
async function validateCustomerKYC(customerCode, firstName, lastName, bvn, nin) {
    try {
        const type = bvn ? 'bvn' : nin ? 'nin' : undefined;
        const value = bvn || nin;
        if (!type || !value) {
            throw new Error('BVN or NIN is required for validation');
        }
        const { data } = await axios_1.default.post(`${BASE_URL}/customer/${customerCode}/identification`, {
            country: 'NG',
            type: type,
            value: value,
            first_name: firstName,
            last_name: lastName,
        }, { headers: HEADERS });
        return data.status;
    }
    catch (error) {
        console.error(`Customer KYC Validation failed:`, error.response?.data?.message || error.message);
        throw new Error(error.response?.data?.message || 'Failed to validate customer KYC');
    }
}
// ─── Create Dedicated Virtual Account for a customer ─────────────────────────
async function createDVA(customerCode, customerName = 'Test User') {
    try {
        const { data } = await axios_1.default.post(`${BASE_URL}/dedicated_account`, {
            customer: customerCode,
            preferred_bank: 'titan-paystack', // Use titan-paystack for real funds in NG
        }, { headers: HEADERS });
        if (!data.status) {
            throw new Error(data.message || 'Failed to create virtual account');
        }
        const acct = data.data;
        return {
            accountNumber: acct.account_number,
            bankName: acct.bank?.name ?? 'Test Bank',
            accountName: acct.account_name,
        };
    }
    catch (error) {
        console.error(`DVA Creation failed:`, error.response?.data?.message || error.message);
        throw new Error(error.response?.data?.message || 'Failed to create virtual account');
    }
}
// ─── Fetch existing DVA for a customer ───────────────────────────────────────
async function fetchDVA(customerCode) {
    try {
        const { data } = await axios_1.default.get(`${BASE_URL}/dedicated_account?customer=${customerCode}`, { headers: HEADERS });
        if (!data.status || !data.data?.length)
            return null;
        const acct = data.data[0];
        return {
            accountNumber: acct.account_number,
            bankName: acct.bank?.name ?? 'Titan-Paystack Bank',
            accountName: acct.account_name,
        };
    }
    catch {
        return null;
    }
}
// ─── Verify webhook signature ─────────────────────────────────────────────────
function verifyWebhookSignature(rawBody, signatureHeader) {
    const hash = crypto_1.default
        .createHmac('sha512', SECRET_KEY)
        .update(rawBody)
        .digest('hex');
    return hash === signatureHeader;
}
// ─── Fetch Banks ──────────────────────────────────────────────────────────────
async function fetchBanks() {
    try {
        const { data } = await axios_1.default.get(`${BASE_URL}/bank?country=nigeria`, { headers: HEADERS });
        if (!data.status)
            throw new Error(data.message);
        return data.data;
    }
    catch (error) {
        console.error('Fetch Banks failed:', error.response?.data?.message || error.message);
        return [];
    }
}
// ─── Verify Account Number ────────────────────────────────────────────────────
async function verifyAccountNumber(accountNumber, bankCode) {
    try {
        const { data } = await axios_1.default.get(`${BASE_URL}/bank/resolve?account_number=${accountNumber}&bank_code=${bankCode}`, { headers: HEADERS });
        if (!data.status)
            throw new Error(data.message);
        return data.data.account_name;
    }
    catch (error) {
        console.error('Verify Account failed:', error.response?.data?.message || error.message);
        throw new Error(error.response?.data?.message || 'Failed to verify account number');
    }
}
// ─── Create Transfer Recipient ────────────────────────────────────────────────
async function createTransferRecipient(name, accountNumber, bankCode) {
    try {
        const { data } = await axios_1.default.post(`${BASE_URL}/transferrecipient`, {
            type: 'nuban',
            name,
            account_number: accountNumber,
            bank_code: bankCode,
            currency: 'NGN',
        }, { headers: HEADERS });
        if (!data.status)
            throw new Error(data.message);
        return data.data.recipient_code;
    }
    catch (error) {
        console.error('Create Recipient failed:', error.response?.data?.message || error.message);
        throw new Error(error.response?.data?.message || 'Failed to create transfer recipient');
    }
}
// ─── Initiate Transfer ────────────────────────────────────────────────────────
async function initiateTransfer(amountNaira, recipientCode, reference) {
    try {
        const { data } = await axios_1.default.post(`${BASE_URL}/transfer`, {
            source: 'balance',
            amount: Math.round(amountNaira * 100), // Convert to kobo
            recipient: recipientCode,
            reason: 'Wallet Withdrawal',
            reference,
        }, { headers: HEADERS });
        if (!data.status)
            throw new Error(data.message);
        return data.data; // Includes status like 'pending', 'success', 'failed'
    }
    catch (error) {
        console.error('Initiate Transfer failed:', error.response?.data?.message || error.message);
        throw new Error(error.response?.data?.message || 'Failed to initiate transfer');
    }
}
//# sourceMappingURL=paystack.service.js.map