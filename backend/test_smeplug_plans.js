const axios = require('axios');
const dotenv = require('dotenv');
dotenv.config();

const BASE_URL = process.env.SMEPLUG_BASE_URL || 'https://smeplug.ng/api/v1';
const API_KEY = process.env.SMEPLUG_API_KEY;

async function run() {
  try {
    const res = await axios.get(`${BASE_URL}/data/plans?network=1`, {
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    console.log("Success:", res.data);
  } catch (err) {
    console.log("Error Status:", err.response?.status);
    console.log("Error Data:", err.response?.data);
  }
}
run();
