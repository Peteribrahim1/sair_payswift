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

async function test() {
  const requestId = generateRequestId();
  console.log("Using Request ID:", requestId);
  const payload = {
    request_id: requestId,
    serviceID: "mtn",
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
    console.log("Response:", JSON.stringify(res.data, null, 2));
  } catch(e: any) {
    console.log("Error:", e.response?.data || e.message);
  }
}
test();
