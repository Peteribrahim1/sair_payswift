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
    const mtnPlans = plansObj.data['1'] || [];

    console.log(`Found ${mtnPlans.length} MTN plans. Testing a few to see if any throw 422...`);
    
    for (let i = 0; i < Math.min(mtnPlans.length, 5); i++) {
      const plan = mtnPlans[i];
      console.log(`Testing plan: ${plan.name} (ID: ${plan.id})`);
      try {
        const purchaseRes = await smeplugClient.post('/data/purchase', {
          network_id: 1, 
          plan_id: Number(plan.id),       
          phone: "08031234567",
          customer_reference: "TEST-" + Date.now() + "-" + i
        });
        console.log(`Result: 200 OK - ${purchaseRes.data.data?.msg || 'Success'}`);
      } catch (err: any) {
        console.error(`Error for ${plan.name}: ${err.response?.status} -`, err.response?.data?.msg || err.message);
      }
      // Wait a sec between requests
      await new Promise(res => setTimeout(res, 1000));
    }
  } catch (e: any) {
    console.error('Error fetching plans:', e.response?.status, e.response?.data, e.message);
  }
}

run();
