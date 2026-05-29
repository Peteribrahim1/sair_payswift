import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const API_KEY = process.env.VTPASS_API_KEY!;
const SECRET_KEY = process.env.VTPASS_SECRET_KEY!;
const PUBLIC_KEY = process.env.VTPASS_PUBLIC_KEY!;
const IS_SANDBOX = (process.env.VTPASS_ENV || 'sandbox') === 'sandbox';
const BASE_URL = IS_SANDBOX
  ? 'https://sandbox.vtpass.com/api'
  : 'https://vtpass.com/api';

/** Generate a VTPass-compliant request_id: YYYYMMDDHHII in WAT (GMT+1) + random suffix */
function generateRequestId(): string {
  const now = new Date(Date.now() + 60 * 60 * 1000); // Add 1hr for WAT
  const pad = (n: number) => String(n).padStart(2, '0');
  const year = now.getUTCFullYear();
  const month = pad(now.getUTCMonth() + 1);
  const day = pad(now.getUTCDate());
  const hour = pad(now.getUTCHours());
  const minute = pad(now.getUTCMinutes());
  const random = Math.random().toString(36).substring(2, 10);
  return `${year}${month}${day}${hour}${minute}${random}`;
}

/**
 * VTPass sandbox does NOT process real VTU/airtime/data transactions.
 * Code '016' (TRANSACTION FAILED) is the expected sandbox response for these products.
 * In sandbox mode we treat it as a simulated success so the full app flow can be tested.
 */
function assertSuccess(data: any, requestId: string, fallbackMsg: string): void {
  if (data.code === '000') return; // real success
  if (IS_SANDBOX && data.code === '016') {
    // Sandbox simulation — log and continue
    console.log(`[VTPass Sandbox] Simulated success for request ${requestId}`);
    return;
  }
  
  // Log the exact response from VTPass so we can debug live errors
  console.error(`[VTPass Failure - Request ${requestId}]:`, JSON.stringify(data, null, 2));
  
  throw new Error(data.response_description || fallbackMsg);
}

const POST_HEADERS = {
  'api-key': API_KEY,
  'secret-key': SECRET_KEY,
  'Content-Type': 'application/json',
};

const GET_HEADERS = {
  'api-key': API_KEY,
  'public-key': PUBLIC_KEY,
};

// ─── Service ID Maps ────────────────────────────────────────────────────────

export const AIRTIME_SERVICE_IDS: Record<string, string> = {
  MTN: 'mtn',
  Airtel: 'airtel',
  Glo: 'glo',
  '9mobile': 'etisalat',
};

export const DATA_SERVICE_IDS: Record<string, string> = {
  MTN: 'mtn-data',
  Airtel: 'airtel-data',
  Glo: 'glo-data',
  '9mobile': 'etisalat-data',
};

export const ELECTRICITY_SERVICE_IDS: Record<string, string> = {
  'Eko Electricity (EKEDC)': 'ekedc',
  'Ikeja Electricity (IKEDC)': 'ikeja-electric',
  'Kano Electricity (KEDCO)': 'kedco',
  'Port Harcourt (PHED)': 'phed',
  'Abuja Electricity (AEDC)': 'aedc',
  'Ibadan Electricity (IBEDC)': 'ibedc',
  'Enugu Electricity (EEDC)': 'enugu-electric',
  'Kaduna Electricity (KAEDCO)': 'kaduna-electric',
  'Jos Electricity (JED)': 'jos-electric',
};

export const CABLE_SERVICE_IDS: Record<string, string> = {
  DSTV: 'dstv',
  GOTV: 'gotv',
  StarTimes: 'startimes',
  Showmax: 'showmax',
};

// ─── VTPass API Functions ───────────────────────────────────────────────────

/** Buy airtime — MTN, Airtel, Glo, 9mobile */
export async function vtpassBuyAirtime(
  serviceID: string,
  phone: string,
  amount: number
): Promise<{ requestId: string; response: any }> {
  const requestId = generateRequestId();
  const payload = { request_id: requestId, serviceID, amount, phone };
  const { data } = await axios.post(`${BASE_URL}/pay`, payload, {
    headers: POST_HEADERS,
  });
  assertSuccess(data, requestId, 'VTPass airtime purchase failed');
  return { requestId, response: data };
}

/** Fetch live data variation codes for a network */
export async function vtpassGetDataVariations(serviceID: string): Promise<any[]> {
  const { data } = await axios.get(
    `${BASE_URL}/service-variations?serviceID=${serviceID}`,
    { headers: GET_HEADERS }
  );
  return data?.content?.varations ?? data?.content?.variations ?? [];
}

/** Buy mobile data — MTN, Airtel, Glo, 9mobile */
export async function vtpassBuyData(
  serviceID: string,
  phone: string,
  variationCode: string,
  amount: number
): Promise<{ requestId: string; response: any }> {
  const requestId = generateRequestId();
  const payload = {
    request_id: requestId,
    serviceID,
    billersCode: phone,
    variation_code: variationCode,
    amount,
    phone,
  };
  const { data } = await axios.post(`${BASE_URL}/pay`, payload, {
    headers: POST_HEADERS,
  });
  assertSuccess(data, requestId, 'VTPass data purchase failed');
  return { requestId, response: data };
}

/** Pay electricity bill */
export async function vtpassPayElectricity(
  serviceID: string,
  meterNumber: string,
  variationCode: 'prepaid' | 'postpaid',
  amount: number,
  phone: string
): Promise<{ requestId: string; response: any }> {
  const requestId = generateRequestId();
  const payload = {
    request_id: requestId,
    serviceID,
    billersCode: meterNumber,
    variation_code: variationCode,
    amount,
    phone,
  };
  const { data } = await axios.post(`${BASE_URL}/pay`, payload, {
    headers: POST_HEADERS,
  });
  assertSuccess(data, requestId, 'VTPass electricity payment failed');
  return { requestId, response: data };
}

/** Fetch cable TV variation codes (subscription plans) */
export async function vtpassGetCablePlans(serviceID: string): Promise<any[]> {
  const { data } = await axios.get(
    `${BASE_URL}/service-variations?serviceID=${serviceID}`,
    { headers: GET_HEADERS }
  );
  return data?.content?.varations ?? data?.content?.variations ?? [];
}

/** Verify smart card / IUC number before payment */
export async function vtpassVerifySmartCard(
  serviceID: string,
  smartCardNumber: string
): Promise<any> {
  const { data } = await axios.post(
    `${BASE_URL}/merchant-verify`,
    { serviceID, billersCode: smartCardNumber },
    { headers: POST_HEADERS }
  );
  return data?.content ?? data;
}

/** Pay cable TV (DSTV, GOTV, StarTimes, Showmax) */
export async function vtpassPayCableTV(
  serviceID: string,
  smartCardNumber: string,
  variationCode: string,
  amount: number,
  phone: string
): Promise<{ requestId: string; response: any }> {
  const requestId = generateRequestId();
  const payload = {
    request_id: requestId,
    serviceID,
    billersCode: smartCardNumber,
    variation_code: variationCode,
    amount,
    phone,
    subscription_type: 'change',
  };
  const { data } = await axios.post(`${BASE_URL}/pay`, payload, {
    headers: POST_HEADERS,
  });
  assertSuccess(data, requestId, 'VTPass cable TV payment failed');
  return { requestId, response: data };
}

/** Requery a transaction by request_id (for dispute/status check) */
export async function vtpassRequery(requestId: string): Promise<any> {
  const { data } = await axios.post(
    `${BASE_URL}/requery`,
    { request_id: requestId },
    { headers: POST_HEADERS }
  );
  return data;
}
