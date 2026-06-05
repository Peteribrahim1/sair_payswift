import axios from 'axios';
import dotenv from 'dotenv';
dotenv.config();

const BASE_URL = 'https://smeplug.ng/api/v1';
const API_KEY = process.env.SMEPLUG_API_KEY || '';

const smeplugClient = axios.create({
  baseURL: BASE_URL,
  headers: {
    Authorization: `Bearer ${API_KEY}`,
    'Content-Type': 'application/json',
  },
});

async function run() {
  try {
    const res = await smeplugClient.post('/data/purchase', {
      network_id: "1", // Some APIs use network_id
      plan_id: "70",   // Some APIs use plan_id
      phone: "08123456789",
      customer_reference: "TEST-1234"
    });
    console.log(res.data);
  } catch (e: any) {
    console.error('Error with network_id/plan_id:', e.response?.status, e.response?.data);
  }

  try {
    const res = await smeplugClient.post('/data/purchase', {
      network: "1",
      plan: "70",
      phone: "08123456789",
      customer_reference: "TEST-1234"
    });
    console.log(res.data);
  } catch (e: any) {
    console.error('Error with network/plan:', e.response?.status, e.response?.data);
  }
}

run();
