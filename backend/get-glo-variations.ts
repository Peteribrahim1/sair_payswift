import dotenv from 'dotenv';
import axios from 'axios';
dotenv.config();

const API_KEY = process.env.VTPASS_API_KEY;
const PUBLIC_KEY = process.env.VTPASS_PUBLIC_KEY;

async function checkVariations(serviceID: string) {
  try {
    const res = await axios.get(`https://sandbox.vtpass.com/api/service-variations?serviceID=${serviceID}`, {
      headers: {
        'api-key': API_KEY,
        'public-key': PUBLIC_KEY,
      }
    });
    const variations = res.data.content.varations;
    console.log(`Variations for ${serviceID}:`);
    for (const v of variations) {
      console.log(`- [${v.variation_code}] ${v.name}`);
    }
  } catch (e: any) {
    console.log("Error:", e.response?.data || e.message);
  }
}

checkVariations('glo-data');
