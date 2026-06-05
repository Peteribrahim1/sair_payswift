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
    
    const longRef = `PENDING-SME-${Date.now()}`;
    console.log(`Testing with reference length ${longRef.length}: ${longRef}`);
    
    const purchaseRes = await smeplugClient.post('/data/purchase', {
      network_id: 1, 
      plan_id: Number(firstPlan.id),       
      phone: "08031234567",
      customer_reference: longRef
    });
    console.log(`Result: 200 OK - ${purchaseRes.data.data?.msg || 'Success'}`);
  } catch (err: any) {
    console.error(`Error: ${err.response?.status} -`, err.response?.data || err.message);
  }
}

run();
