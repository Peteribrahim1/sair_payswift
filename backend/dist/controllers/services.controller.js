"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getActiveAdverts = exports.buySmeData = exports.getSmePlans = exports.handleAirtimeWebhook = exports.convertAirtime = exports.transact = exports.payCableTV = exports.payElectricity = exports.buyData = exports.buyAirtime = exports.verifyMeter = exports.verifySmartCard = exports.getCablePlans = exports.getDataPlans = void 0;
const prisma_1 = require("../prisma");
const vtpass_service_1 = require("../services/vtpass.service");
const airtime_cash_service_1 = require("../services/airtime-cash.service");
const smeplug_service_1 = require("../services/smeplug.service");
// ─── Helper: Sanitize Provider Errors ──────────────────────────────────────────
function sanitizeProviderError(errMsg, defaultMsg) {
    if (!errMsg)
        return defaultMsg;
    const lowerMsg = errMsg.toLowerCase();
    if (lowerMsg.includes('insufficient') || lowerMsg.includes('balance') || lowerMsg.includes('wallet')) {
        return 'Service provider is currently unavailable. Please try again later.';
    }
    return errMsg;
}
// ─── Helper: Atomic Debit ──────────────────────────────────────────────────────
async function debitWalletAndCreateTx(userId, amount, type, reference, phone, network) {
    if (amount <= 0)
        throw new Error('Amount must be greater than zero');
    const result = await prisma_1.prisma.user.updateMany({
        where: { id: userId, balance: { gte: amount } },
        data: { balance: { decrement: amount } },
    });
    if (result.count === 0) {
        throw new Error(`Insufficient balance. Total charge is ₦${amount.toFixed(2)}`);
    }
    return prisma_1.prisma.transaction.create({
        data: { userId, amount, type, status: 'PENDING', reference, phone, network },
    });
}
// ─── Helper: Refund Wallet on Failure ─────────────────────────────────────────
async function refundWalletAndFailTx(userId, amount, txId) {
    await prisma_1.prisma.$transaction([
        prisma_1.prisma.user.update({
            where: { id: userId },
            data: { balance: { increment: amount } },
        }),
        prisma_1.prisma.transaction.update({
            where: { id: txId },
            data: { status: 'FAILED' },
        }),
    ]);
}
// ─── Helper: Complete Transaction & Notify ────────────────────────────────────
async function completeTransaction(userId, txId, title, message) {
    await prisma_1.prisma.$transaction([
        prisma_1.prisma.transaction.update({
            where: { id: txId },
            data: { status: 'COMPLETED' },
        }),
        prisma_1.prisma.notification.create({
            data: { userId, title, message },
        }),
    ]);
    // Return updated user balance
    return prisma_1.prisma.user.findUnique({ where: { id: userId }, select: { balance: true } });
}
// ─── GET /api/services/data-plans/:network ───────────────────────────────────
const getDataPlans = async (req, res) => {
    const { network } = req.params;
    const serviceID = vtpass_service_1.DATA_SERVICE_IDS[network];
    if (!serviceID)
        return res.status(400).json({ error: `Unknown network: ${network}` });
    try {
        const plans = await (0, vtpass_service_1.vtpassGetDataVariations)(serviceID);
        // Apply dynamic markup
        let markup = 5.0;
        const config = await prisma_1.prisma.appConfig.findUnique({ where: { id: 'global-config' } });
        if (config)
            markup = config.dataMarkupPercent;
        const markedUpPlans = plans.map((p) => {
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
    }
    catch (error) {
        console.error('getDataPlans error:', error.message);
        res.status(500).json({ error: 'Failed to fetch data plans' });
    }
};
exports.getDataPlans = getDataPlans;
// ─── GET /api/services/cable-plans/:provider ─────────────────────────────────
const getCablePlans = async (req, res) => {
    const { provider } = req.params;
    const serviceID = vtpass_service_1.CABLE_SERVICE_IDS[provider];
    if (!serviceID)
        return res.status(400).json({ error: `Unknown provider: ${provider}` });
    try {
        const plans = await (0, vtpass_service_1.vtpassGetCablePlans)(serviceID);
        res.json({ plans });
    }
    catch (error) {
        console.error('getCablePlans error:', error.message);
        res.status(500).json({ error: 'Failed to fetch cable plans' });
    }
};
exports.getCablePlans = getCablePlans;
// ─── POST /api/services/verify-smartcard ─────────────────────────────────────
const verifySmartCard = async (req, res) => {
    const { provider, smartCardNumber } = req.body;
    const serviceID = vtpass_service_1.CABLE_SERVICE_IDS[provider];
    if (!serviceID)
        return res.status(400).json({ error: `Unknown provider: ${provider}` });
    try {
        const info = await (0, vtpass_service_1.vtpassVerifySmartCard)(serviceID, smartCardNumber);
        res.json({ info });
    }
    catch (error) {
        console.error('verifySmartCard error:', error.message);
        res.status(500).json({ error: 'Failed to verify smart card' });
    }
};
exports.verifySmartCard = verifySmartCard;
// ─── POST /api/services/verify-meter ─────────────────────────────────────────
const verifyMeter = async (req, res) => {
    const { provider, meterNumber } = req.body;
    const serviceID = vtpass_service_1.ELECTRICITY_SERVICE_IDS[provider];
    if (!serviceID)
        return res.status(400).json({ error: `Unknown provider: ${provider}` });
    try {
        const info = await (0, vtpass_service_1.vtpassVerifySmartCard)(serviceID, meterNumber);
        res.json({ info });
    }
    catch (error) {
        console.error('verifyMeter error:', error.message);
        res.status(500).json({ error: 'Failed to verify meter number' });
    }
};
exports.verifyMeter = verifyMeter;
// ─── POST /api/services/airtime ──────────────────────────────────────────────
const buyAirtime = async (req, res) => {
    const { network, phone, amount } = req.body;
    const userId = req.user.id;
    if (!network || !phone || !amount) {
        return res.status(400).json({ error: 'network, phone and amount are required' });
    }
    const faceValue = parseFloat(amount.toString());
    if (isNaN(faceValue) || faceValue <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
    }
    const serviceID = vtpass_service_1.AIRTIME_SERVICE_IDS[network];
    if (!serviceID)
        return res.status(400).json({ error: `Unknown network: ${network}` });
    try {
        let markup = 2.0;
        const config = await prisma_1.prisma.appConfig.findUnique({ where: { id: 'global-config' } });
        if (config)
            markup = config.airtimeMarkupPercent;
        const totalCharge = faceValue + (faceValue * (markup / 100));
        // 1. Atomically debit the wallet
        const tx = await debitWalletAndCreateTx(userId, totalCharge, 'AIRTIME', `PENDING-${Date.now()}`, phone, network);
        try {
            // 2. Call VTPass
            const { requestId } = await (0, vtpass_service_1.vtpassBuyAirtime)(serviceID, phone, faceValue);
            // 3. Complete and notify
            await prisma_1.prisma.transaction.update({ where: { id: tx.id }, data: { reference: requestId } }); // Update ref
            const user = await completeTransaction(userId, tx.id, 'Transaction Successful', `₦${faceValue} airtime sent to ${phone} (${network})`);
            res.json({ success: true, balance: user?.balance, transaction: { ...tx, status: 'COMPLETED', reference: requestId } });
        }
        catch (apiError) {
            // Refund if VTPass fails
            await refundWalletAndFailTx(userId, totalCharge, tx.id);
            throw new Error(sanitizeProviderError(apiError.message, 'Airtime purchase failed at provider'));
        }
    }
    catch (error) {
        console.error('buyAirtime error:', error.message);
        res.status(500).json({ error: error.message || 'Airtime purchase failed' });
    }
};
exports.buyAirtime = buyAirtime;
// ─── POST /api/services/data ─────────────────────────────────────────────────
const buyData = async (req, res) => {
    const { network, phone, variationCode } = req.body;
    const userId = req.user.id;
    if (!network || !phone || !variationCode) {
        return res.status(400).json({ error: 'network, phone, variationCode are required' });
    }
    const serviceID = vtpass_service_1.DATA_SERVICE_IDS[network];
    if (!serviceID)
        return res.status(400).json({ error: `Unknown network: ${network}` });
    try {
        // 1. Fetch raw variations to find the raw amount
        const plans = await (0, vtpass_service_1.vtpassGetDataVariations)(serviceID);
        const plan = plans.find((p) => p.variation_code === variationCode);
        if (!plan)
            return res.status(400).json({ error: 'Invalid data plan selected' });
        const rawPrice = parseFloat(plan.variation_amount);
        if (isNaN(rawPrice) || rawPrice <= 0)
            return res.status(400).json({ error: 'Invalid data plan amount' });
        let markup = 5.0;
        const config = await prisma_1.prisma.appConfig.findUnique({ where: { id: 'global-config' } });
        if (config)
            markup = config.dataMarkupPercent;
        const totalCharge = rawPrice + (rawPrice * (markup / 100));
        // 2. Atomically debit the wallet
        const tx = await debitWalletAndCreateTx(userId, totalCharge, 'DATA', `PENDING-${Date.now()}`, phone, network);
        try {
            // 3. Call VTPass
            const { requestId } = await (0, vtpass_service_1.vtpassBuyData)(serviceID, phone, variationCode, rawPrice);
            // 4. Complete and notify
            await prisma_1.prisma.transaction.update({ where: { id: tx.id }, data: { reference: requestId } });
            const user = await completeTransaction(userId, tx.id, 'Transaction Successful', `₦${rawPrice} data bundle sent to ${phone} (${network})`);
            res.json({ success: true, balance: user?.balance, transaction: { ...tx, status: 'COMPLETED', reference: requestId } });
        }
        catch (apiError) {
            // Refund if VTPass fails
            await refundWalletAndFailTx(userId, totalCharge, tx.id);
            throw new Error(sanitizeProviderError(apiError.message, 'Data purchase failed at provider'));
        }
    }
    catch (error) {
        console.error('buyData error:', error.message);
        res.status(500).json({ error: error.message || 'Data purchase failed' });
    }
};
exports.buyData = buyData;
// ─── POST /api/services/electricity ──────────────────────────────────────────
const payElectricity = async (req, res) => {
    const { provider, meterNumber, meterType, amount, phone } = req.body;
    const userId = req.user.id;
    if (!provider || !meterNumber || !meterType || !amount || !phone) {
        return res.status(400).json({ error: 'provider, meterNumber, meterType, amount and phone are required' });
    }
    const rawAmount = parseFloat(amount.toString());
    if (isNaN(rawAmount) || rawAmount <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
    }
    const serviceID = vtpass_service_1.ELECTRICITY_SERVICE_IDS[provider];
    if (!serviceID)
        return res.status(400).json({ error: `Unknown provider: ${provider}` });
    const variationCode = meterType === 'prepaid' ? 'prepaid' : 'postpaid';
    try {
        let fee = 50.0;
        const config = await prisma_1.prisma.appConfig.findUnique({ where: { id: 'global-config' } });
        if (config)
            fee = config.billConvenienceFee;
        const totalCharge = rawAmount + fee;
        // 1. Atomically debit the wallet
        const tx = await debitWalletAndCreateTx(userId, totalCharge, 'ELECTRICITY', `PENDING-${Date.now()}`, phone, provider);
        try {
            // 2. Call VTPass
            const { requestId } = await (0, vtpass_service_1.vtpassPayElectricity)(serviceID, meterNumber, variationCode, rawAmount, phone);
            // 3. Complete and notify
            await prisma_1.prisma.transaction.update({ where: { id: tx.id }, data: { reference: requestId } });
            const user = await completeTransaction(userId, tx.id, 'Transaction Successful', `₦${rawAmount} electricity payment for meter ${meterNumber} (${provider})`);
            res.json({ success: true, balance: user?.balance, transaction: { ...tx, status: 'COMPLETED', reference: requestId } });
        }
        catch (apiError) {
            // Refund if VTPass fails
            await refundWalletAndFailTx(userId, totalCharge, tx.id);
            throw new Error(sanitizeProviderError(apiError.message, 'Electricity payment failed at provider'));
        }
    }
    catch (error) {
        console.error('payElectricity error:', error.message);
        res.status(500).json({ error: error.message || 'Electricity payment failed' });
    }
};
exports.payElectricity = payElectricity;
// ─── POST /api/services/cable ────────────────────────────────────────────────
const payCableTV = async (req, res) => {
    const { provider, smartCardNumber, variationCode, amount, phone } = req.body;
    const userId = req.user.id;
    if (!provider || !smartCardNumber || !variationCode || !amount || !phone) {
        return res.status(400).json({ error: 'provider, smartCardNumber, variationCode, amount and phone are required' });
    }
    const rawAmount = parseFloat(amount.toString());
    if (isNaN(rawAmount) || rawAmount <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
    }
    const serviceID = vtpass_service_1.CABLE_SERVICE_IDS[provider];
    if (!serviceID)
        return res.status(400).json({ error: `Unknown provider: ${provider}` });
    try {
        let fee = 50.0;
        const config = await prisma_1.prisma.appConfig.findUnique({ where: { id: 'global-config' } });
        if (config)
            fee = config.billConvenienceFee;
        const totalCharge = rawAmount + fee;
        // 1. Atomically debit the wallet
        const tx = await debitWalletAndCreateTx(userId, totalCharge, 'CABLE_TV', `PENDING-${Date.now()}`, phone, provider);
        try {
            // 2. Call VTPass
            const { requestId } = await (0, vtpass_service_1.vtpassPayCableTV)(serviceID, smartCardNumber, variationCode, rawAmount, phone);
            // 3. Complete and notify
            await prisma_1.prisma.transaction.update({ where: { id: tx.id }, data: { reference: requestId } });
            const user = await completeTransaction(userId, tx.id, 'Transaction Successful', `₦${rawAmount} ${provider} subscription for card ${smartCardNumber}`);
            res.json({ success: true, balance: user?.balance, transaction: { ...tx, status: 'COMPLETED', reference: requestId } });
        }
        catch (apiError) {
            // Refund if VTPass fails
            await refundWalletAndFailTx(userId, totalCharge, tx.id);
            throw new Error(sanitizeProviderError(apiError.message, 'Cable TV payment failed at provider'));
        }
    }
    catch (error) {
        console.error('payCableTV error:', error.message);
        res.status(500).json({ error: error.message || 'Cable TV payment failed' });
    }
};
exports.payCableTV = payCableTV;
// ─── POST /api/services/transact (legacy — FUND / CONVERT_AIRTIME credits only) ──
const transact = async (req, res) => {
    const { amount, type } = req.body;
    const userId = req.user.id;
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
        const result = await prisma_1.prisma.$transaction([
            prisma_1.prisma.user.update({
                where: { id: userId },
                data: { balance: { increment: parsedAmount } },
            }),
            prisma_1.prisma.transaction.create({
                data: { userId, amount: parsedAmount, type, status: 'COMPLETED', reference: null },
            }),
            prisma_1.prisma.notification.create({
                data: {
                    userId,
                    title: 'Transaction Successful',
                    message: `Your transaction of ₦${parsedAmount} for ${type} was successful.`,
                },
            }),
        ]);
        res.json({ success: true, balance: result[0].balance, transaction: result[1] });
    }
    catch (error) {
        res.status(500).json({ error: 'Transaction failed' });
    }
};
exports.transact = transact;
// ─── POST /api/services/convert-airtime ──────────────────────────────────────
const convertAirtime = async (req, res) => {
    const { amount, network, phone } = req.body;
    const userId = req.user.id;
    if (!amount || !network || !phone) {
        return res.status(400).json({ error: 'amount, network, and phone are required' });
    }
    try {
        const result = await airtime_cash_service_1.AirtimeCashService.initializeConversion(amount, network, phone, userId);
        res.json(result);
    }
    catch (error) {
        console.error('convertAirtime error:', error.message);
        res.status(500).json({ error: error.message || 'Failed to initialize conversion' });
    }
};
exports.convertAirtime = convertAirtime;
// ─── POST /api/webhooks/airtime ──────────────────────────────────────────────
const handleAirtimeWebhook = async (req, res) => {
    try {
        const result = await airtime_cash_service_1.AirtimeCashService.handleWebhook(req.body);
        if (result.success) {
            res.json({ success: true });
        }
        else {
            res.status(400).json({ success: false, message: result.message });
        }
    }
    catch (error) {
        console.error('Webhook error:', error.message);
        res.status(500).json({ error: 'Webhook processing failed' });
    }
};
exports.handleAirtimeWebhook = handleAirtimeWebhook;
// ─── SMEPlug (SME Data Plans) ───────────────────────────────────────────────
const getSmePlans = async (req, res) => {
    const { network } = req.params;
    const networkId = smeplug_service_1.SMEPLUG_NETWORK_IDS[network];
    if (!networkId)
        return res.status(400).json({ error: `Unknown network: ${network}` });
    try {
        const plans = await (0, smeplug_service_1.smeplugGetDataPlans)(networkId);
        // Add dynamic markup
        let markup = 5.0;
        const config = await prisma_1.prisma.appConfig.findUnique({ where: { id: 'global-config' } });
        if (config)
            markup = config.dataMarkupPercent;
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
    }
    catch (error) {
        console.error('getSmePlans error:', error.message);
        res.status(500).json({ error: error.message || 'Failed to fetch SME plans' });
    }
};
exports.getSmePlans = getSmePlans;
const buySmeData = async (req, res) => {
    const { network, phone, planId, rawPrice } = req.body;
    const userId = req.user.id;
    if (!network || !phone || !planId || !rawPrice) {
        return res.status(400).json({ error: 'network, phone, planId, rawPrice are required' });
    }
    const networkId = smeplug_service_1.SMEPLUG_NETWORK_IDS[network];
    if (!networkId)
        return res.status(400).json({ error: `Unknown network: ${network}` });
    const parsedRawPrice = parseFloat(rawPrice.toString());
    if (isNaN(parsedRawPrice) || parsedRawPrice <= 0) {
        return res.status(400).json({ error: 'Invalid raw price' });
    }
    try {
        // 1. Get dynamic markup
        let markup = 5.0;
        const config = await prisma_1.prisma.appConfig.findUnique({ where: { id: 'global-config' } });
        if (config)
            markup = config.dataMarkupPercent;
        const totalCharge = parsedRawPrice + (parsedRawPrice * (markup / 100));
        // 2. Atomically debit the wallet
        const tx = await debitWalletAndCreateTx(userId, totalCharge, 'DATA_SME', `PENDING-SME-${Date.now()}`, phone, network);
        try {
            // 3. Call SMEPlug API
            const { reference } = await (0, smeplug_service_1.smeplugBuyData)(networkId, planId, phone, tx.reference);
            // 4. Complete and notify
            await prisma_1.prisma.transaction.update({ where: { id: tx.id }, data: { reference: reference } });
            const user = await completeTransaction(userId, tx.id, 'Transaction Successful', `₦${totalCharge.toFixed(2)} SME data sent to ${phone} (${network})`);
            res.json({ success: true, balance: user?.balance, transaction: { ...tx, status: 'COMPLETED', reference: reference } });
        }
        catch (apiError) {
            // Refund if SMEPlug fails
            await refundWalletAndFailTx(userId, totalCharge, tx.id);
            let providerMsg = apiError.response?.data?.msg || apiError.response?.data?.message || apiError.message;
            if (apiError.response?.data?.errors) {
                providerMsg += ' | Details: ' + JSON.stringify(apiError.response.data.errors);
            }
            throw new Error(sanitizeProviderError(providerMsg, 'SME Data purchase failed at provider'));
        }
    }
    catch (error) {
        console.error('buySmeData error:', error.message);
        res.status(500).json({ error: error.message || 'SME Data purchase failed' });
    }
};
exports.buySmeData = buySmeData;
// ─── Adverts ────────────────────────────────────────────────────────────────
const getActiveAdverts = async (req, res) => {
    try {
        const adverts = await prisma_1.prisma.advert.findMany({
            where: { isActive: true },
            orderBy: { createdAt: 'desc' },
        });
        res.json({ success: true, adverts });
    }
    catch (error) {
        console.error('Get adverts error:', error);
        res.status(500).json({ error: 'Failed to fetch adverts.' });
    }
};
exports.getActiveAdverts = getActiveAdverts;
//# sourceMappingURL=services.controller.js.map