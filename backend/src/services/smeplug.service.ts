import axios from 'axios';

const BASE_URL = process.env.SMEPLUG_BASE_URL || 'https://smeplug.ng/api/v1';
const API_KEY = process.env.SMEPLUG_API_KEY || '';

const smeplugClient = axios.create({
  baseURL: BASE_URL,
  headers: {
    Authorization: `Bearer ${API_KEY}`,
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});

// Network ID mapping (SMEPlug uses numeric IDs)
export const SMEPLUG_NETWORK_IDS: Record<string, number> = {
  MTN: 1,
  Airtel: 2,
  '9mobile': 3,
  Glo: 4,
};

/**
 * Fetch all data plans for a given network from SMEPlug.
 * Returns only plans that have a valid price > 0.
 */
export async function smeplugGetDataPlans(networkId: number): Promise<any[]> {
  const response = await smeplugClient.get(`/data/plans?network=${networkId}`);
  const data = response.data;

  if (!data.status || !data.data) {
    throw new Error('SMEPlug returned no plans');
  }

  // Filter out plans with price = 0 (unavailable/out of stock)
  const plans: any[] = data.data[networkId.toString()] || [];
  
  return plans
    .filter((p: any) => p.price > 0)
    .map((p: any) => ({
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
export async function smeplugBuyData(
  networkId: number,
  planId: number,
  phone: string,
  reference: string
): Promise<{ reference: string; status: string }> {
  const response = await smeplugClient.post('/data/purchase', {
    network_id: String(networkId),
    network: String(networkId),
    plan_id: String(planId),
    plan: String(planId),
    phone: phone,
    phone_number: phone,
    customer_reference: reference,
    ref: reference,
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
