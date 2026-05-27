import dotenv from 'dotenv';
import axios from 'axios';
dotenv.config();

const API_KEY = process.env.VTPASS_API_KEY;
const SECRET_KEY = process.env.VTPASS_SECRET_KEY;

async function verifyBiller() {
  const payload = {
    serviceID: "ikeja-electric",
    billersCode: "1111111111111", // VTPass success meter number
    type: "prepaid"
  };

  try {
    const res = await axios.post("https://sandbox.vtpass.com/api/merchant-verify", payload, {
      headers: {
        'api-key': API_KEY,
        'secret-key': SECRET_KEY,
        'Content-Type': 'application/json',
      }
    });
    console.log("✅ VERIFICATION SUCCESS:\n", JSON.stringify(res.data, null, 2));
  } catch(e: any) {
    console.log(`❌ ERROR:`, e.response?.data || e.message);
  }
}

verifyBiller();
