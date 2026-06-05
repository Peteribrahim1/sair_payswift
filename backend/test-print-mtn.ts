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
    
    console.log(`Network 1 length:`, plansObj.data['1']?.length);
    console.log(`Network 2 length:`, plansObj.data['2']?.length);
    console.log(`Network 3 length:`, plansObj.data['3']?.length);
    console.log(`Network 4 length:`, plansObj.data['4']?.length);
  } catch (e: any) {
    console.error('Error:', e.response?.data || e.message);
  }
}

run();
