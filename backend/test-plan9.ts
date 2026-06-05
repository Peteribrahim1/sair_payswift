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
    
    const plan9 = mtnPlans.find((p: any) => p.id == 9 || p.id === '9');
    console.log('Is Plan 9 in MTN plans?', plan9);
  } catch (e: any) {
    console.error('Error:', e.response?.data || e.message);
  }
}

run();
