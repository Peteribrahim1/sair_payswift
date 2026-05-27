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

async function buyData(serviceID: string, variationCode: string, amount: number) {
  const requestId = generateRequestId();
  const payload = {
    request_id: requestId,
    serviceID: serviceID,
    billersCode: "08011111111",
    variation_code: variationCode,
    amount: amount,
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
      console.log(`✅ SUCCESS -> Request ID: ${requestId} | Service: ${serviceID} | Variation: ${variationCode}`);
    } else {
      console.log(`❌ FAILED ->`, res.data);
    }
  } catch(e: any) {
    console.log(`❌ ERROR ->`, e.response?.data || e.message);
  }
}

async function run() {
  console.log("Fetching Airtel variations...");
  const airtelRes = await axios.get(`https://sandbox.vtpass.com/api/service-variations?serviceID=airtel-data`, {
    headers: { 'api-key': API_KEY, 'public-key': PUBLIC_KEY }
  });
  const airtelVar = airtelRes.data.content.varations[2]; // Use index 2 to bypass duplicate check!
  await buyData('airtel-data', airtelVar.variation_code, parseFloat(airtelVar.variation_amount));

  console.log("Fetching Glo SME Data (Best Value)...");
  try {
    const gloSmeRes = await axios.get(`https://sandbox.vtpass.com/api/service-variations?serviceID=glo-sme-data`, {
      headers: { 'api-key': API_KEY, 'public-key': PUBLIC_KEY }
    });
    const gloSmeVar = gloSmeRes.data.content.varations[2]; // Use index 2
    if (gloSmeVar) {
      await buyData('glo-sme-data', gloSmeVar.variation_code, parseFloat(gloSmeVar.variation_amount));
      return;
    }
  } catch (e) {
    console.log("Failed to fetch Glo SME data:", (e as any).message);
  }
}

run();
