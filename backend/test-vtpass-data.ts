import dotenv from 'dotenv';
import axios from 'axios';
dotenv.config();

const API_KEY = process.env.VTPASS_API_KEY;
const SECRET_KEY = process.env.VTPASS_SECRET_KEY;
const PUBLIC_KEY = process.env.VTPASS_PUBLIC_KEY;

function generateRequestId(): string {
  const now = new Date(Date.now() + 60 * 60 * 1000); 
  const pad = (n: number) => String(n).padStart(2, '0');
  const year = now.getUTCFullYear();
  const month = pad(now.getUTCMonth() + 1);
  const day = pad(now.getUTCDate());
  const hour = pad(now.getUTCHours());
  const minute = pad(now.getUTCMinutes());
  const random = Math.random().toString(36).substring(2, 10);
  return `${year}${month}${day}${hour}${minute}${random}`;
}

async function runDataTest(network: string) {
  try {
    // 1. Get variation code
    const serviceID = `${network}-data`;
    const variationsRes = await axios.get(`https://sandbox.vtpass.com/api/service-variations?serviceID=${serviceID}`, {
      headers: {
        'api-key': API_KEY,
        'public-key': PUBLIC_KEY,
      }
    });

    const variations = variationsRes.data.content.varations;
    if (!variations || variations.length === 0) {
      console.log(`❌ ${network.toUpperCase()} FAILED to fetch variations`);
      return;
    }
    const variation = variations[0]; // pick the first data plan

    // 2. Make purchase
    const requestId = generateRequestId();
    const payload = {
      request_id: requestId,
      serviceID: serviceID,
      billersCode: "08011111111",
      variation_code: variation.variation_code,
      amount: parseFloat(variation.variation_amount),
      phone: "08011111111"
    };

    const res = await axios.post("https://sandbox.vtpass.com/api/pay", payload, {
      headers: {
        'api-key': API_KEY,
        'secret-key': SECRET_KEY,
        'Content-Type': 'application/json',
      }
    });
    if (res.data.code === '000') {
      console.log(`✅ ${network.toUpperCase()} DATA SUCCESS -> Request ID: ${requestId} | Plan: ${variation.name}`);
    } else {
      console.log(`❌ ${network.toUpperCase()} DATA FAILED ->`, JSON.stringify(res.data));
    }
  } catch(e: any) {
    console.log(`❌ ${network.toUpperCase()} DATA ERROR ->`, e.response?.data || e.message);
  }
}

async function testAll() {
  await runDataTest('mtn');
  await new Promise(r => setTimeout(r, 1000));
  await runDataTest('airtel');
  await new Promise(r => setTimeout(r, 1000));
  await runDataTest('glo');
  await new Promise(r => setTimeout(r, 1000));
  await runDataTest('etisalat');
}

testAll();
