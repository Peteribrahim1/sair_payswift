import dotenv from 'dotenv';
import axios from 'axios';
dotenv.config();

const API_KEY = process.env.VTPASS_API_KEY;
const SECRET_KEY = process.env.VTPASS_SECRET_KEY;

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

async function runTest(network: string) {
  const requestId = generateRequestId();
  const payload = {
    request_id: requestId,
    serviceID: network,
    amount: 100,
    phone: "08011111111"
  };

  try {
    const res = await axios.post("https://sandbox.vtpass.com/api/pay", payload, {
      headers: {
        'api-key': API_KEY,
        'secret-key': SECRET_KEY,
        'Content-Type': 'application/json',
      }
    });
    if (res.data.code === '000') {
      console.log(`✅ ${network.toUpperCase()} SUCCESS -> Request ID: ${requestId}`);
    } else {
      console.log(`❌ ${network.toUpperCase()} FAILED ->`, res.data);
    }
  } catch(e: any) {
    console.log(`❌ ${network.toUpperCase()} ERROR ->`, e.response?.data || e.message);
  }
}

async function testAll() {
  await runTest('airtel');
  await new Promise(r => setTimeout(r, 1000));
  await runTest('glo');
  await new Promise(r => setTimeout(r, 1000));
  await runTest('etisalat');
}

testAll();
