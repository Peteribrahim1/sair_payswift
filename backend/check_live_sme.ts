import axios from 'axios';
import dotenv from 'dotenv';
dotenv.config();

async function printAllPlans() {
  const url = process.env.VTPASS_API_URL || 'https://sandbox.vtpass.com/api';
  const apiKey = process.env.VTPASS_API_KEY;
  const publicKey = process.env.VTPASS_PUBLIC_KEY;

  try {
    const varRes = await axios.get(`${url}/service-variations?serviceID=mtn-data`, {
      headers: { 'api-key': apiKey, 'public-key': publicKey }
    });
    const variations = varRes.data.content.varations;
    variations.forEach((v: any) => console.log(v.name));
  } catch(e: any) {
    console.error("Error:", e.response?.data || e.message);
  }
}

printAllPlans();
