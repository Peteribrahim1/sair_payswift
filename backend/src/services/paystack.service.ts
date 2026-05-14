import axios from 'axios';
import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();

const SECRET_KEY = process.env.PAYSTACK_SECRET_KEY!;
const BASE_URL = 'https://api.paystack.co';

const HEADERS = {
  Authorization: `Bearer ${SECRET_KEY}`,
  'Content-Type': 'application/json',
};

// ─── Create a Paystack Customer ───────────────────────────────────────────────
export async function createCustomer(
  email: string,
  firstName: string,
  lastName: string
): Promise<{ customerCode: string }> {
  const { data } = await axios.post(
    `${BASE_URL}/customer`,
    { email, first_name: firstName, last_name: lastName },
    { headers: HEADERS }
  );
  if (!data.status) throw new Error(data.message || 'Failed to create Paystack customer');
  return { customerCode: data.data.customer_code };
}

// ─── Validate Paystack Customer (KYC) ─────────────────────────────────────────
export async function validateCustomerKYC(
  customerCode: string,
  firstName: string,
  lastName: string,
  bvn?: string,
  nin?: string
): Promise<boolean> {
  try {
    const type = bvn ? 'bvn' : nin ? 'nin' : undefined;
    const value = bvn || nin;
    
    if (!type || !value) {
      throw new Error('BVN or NIN is required for validation');
    }

    const { data } = await axios.post(
      `${BASE_URL}/customer/${customerCode}/identification`,
      {
        country: 'NG',
        type: type,
        value: value,
        first_name: firstName,
        last_name: lastName,
      },
      { headers: HEADERS }
    );

    return data.status;
  } catch (error: any) {
    console.error(`Customer KYC Validation failed:`, error.response?.data?.message || error.message);
    throw new Error(error.response?.data?.message || 'Failed to validate customer KYC');
  }
}

// ─── Create Dedicated Virtual Account for a customer ─────────────────────────
export async function createDVA(customerCode: string, customerName: string = 'Test User'): Promise<{
  accountNumber: string;
  bankName: string;
  accountName: string;
}> {
  try {
    const { data } = await axios.post(
      `${BASE_URL}/dedicated_account`,
      {
        customer: customerCode,
        preferred_bank: 'titan-paystack', // Use titan-paystack for real funds in NG
      },
      { headers: HEADERS }
    );

    if (!data.status) {
      throw new Error(data.message || 'Failed to create virtual account');
    }

    const acct = data.data;
    return {
      accountNumber: acct.account_number,
      bankName: acct.bank?.name ?? 'Test Bank',
      accountName: acct.account_name,
    };
  } catch (error: any) {
    console.error(`DVA Creation failed:`, error.response?.data?.message || error.message);
    throw new Error(error.response?.data?.message || 'Failed to create virtual account');
  }
}

// ─── Fetch existing DVA for a customer ───────────────────────────────────────
export async function fetchDVA(customerCode: string): Promise<{
  accountNumber: string;
  bankName: string;
  accountName: string;
} | null> {
  try {
    const { data } = await axios.get(
      `${BASE_URL}/dedicated_account?customer=${customerCode}`,
      { headers: HEADERS }
    );
    if (!data.status || !data.data?.length) return null;
    const acct = data.data[0];
    return {
      accountNumber: acct.account_number,
      bankName: acct.bank?.name ?? 'Titan-Paystack Bank',
      accountName: acct.account_name,
    };
  } catch {
    return null;
  }
}

// ─── Verify webhook signature ─────────────────────────────────────────────────
export function verifyWebhookSignature(
  rawBody: string,
  signatureHeader: string
): boolean {
  const hash = crypto
    .createHmac('sha512', SECRET_KEY)
    .update(rawBody)
    .digest('hex');
  return hash === signatureHeader;
}
