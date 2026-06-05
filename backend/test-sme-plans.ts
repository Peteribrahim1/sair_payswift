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
    const plansRes = await smeplugClient.get('/data/plans?network=1');
    const plansObj = plansRes.data; 
    const firstPlan = plansObj.data['1'][0];
    const planId = Number(firstPlan.id);
    const networkId = Number(1);

    console.log(`Sending payload with BAD phone format: network_id: ${networkId}, plan_id: ${planId}`);
    const purchaseRes = await smeplugClient.post('/data/purchase', {
      network_id: networkId, 
      plan_id: planId,       
      phone: "080312345", // too short
      customer_reference: "TEST-" + Date.now()
    });
    console.log('Purchase Response:', purchaseRes.data);
  } catch (e: any) {
    console.error('Error:', e.response?.status, e.response?.data, e.message);
  }
}

run();
