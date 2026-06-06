"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SMEPLUG_NETWORK_IDS = void 0;
exports.smeplugGetDataPlans = smeplugGetDataPlans;
exports.smeplugBuyData = smeplugBuyData;
const axios_1 = __importDefault(require("axios"));
const BASE_URL = process.env.SMEPLUG_BASE_URL || 'https://smeplug.ng/api/v1';
const API_KEY = process.env.SMEPLUG_API_KEY || '';
const smeplugClient = axios_1.default.create({
    baseURL: BASE_URL,
    headers: {
        Authorization: `Bearer ${API_KEY}`,
        'Content-Type': 'application/json',
    },
    timeout: 30000,
});
// Network ID mapping (SMEPlug uses numeric IDs)
exports.SMEPLUG_NETWORK_IDS = {
    MTN: 1,
    Airtel: 2,
    '9mobile': 3,
    Glo: 4,
};
/**
 * Fetch all data plans for a given network from SMEPlug.
 * Returns only plans that have a valid price > 0.
 */
async function smeplugGetDataPlans(networkId) {
    const response = await smeplugClient.get(`/data/plans?network=${networkId}`);
    const data = response.data;
    if (!data.status || !data.data) {
        throw new Error('SMEPlug returned no plans');
    }
    // Filter out plans with price = 0 (unavailable/out of stock)
    const plans = data.data[networkId.toString()] || [];
    return plans
        .filter((p) => p.price > 0)
        .map((p) => ({
        id: p.id,
        name: p.name,
        price: p.price,
        raw_price: p.price,
    }));
}
/**
 * Purchase a data plan from SMEPlug.
 * Returns the transaction reference and status.
 */
async function smeplugBuyData(networkId, planId, phone, reference) {
    const response = await smeplugClient.post('/data/purchase', {
        network_id: networkId,
        plan_id: planId,
        phone,
        customer_reference: reference,
    });
    const data = response.data;
    if (!data.status) {
        throw new Error(data.message || data.msg || 'SMEPlug purchase failed');
    }
    return {
        reference: data.ref || reference,
        status: data.status ? 'success' : 'failed',
    };
}
//# sourceMappingURL=smeplug.service.js.map