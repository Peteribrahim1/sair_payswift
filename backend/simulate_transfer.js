const crypto = require('crypto');
const axios = require('axios');
const dotenv = require('dotenv');

dotenv.config();

const SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;
const webhookUrl = 'http://localhost:3000/api/wallet/webhook';

async function simulate() {
  const payload = {
    event: 'charge.success',
    data: {
      channel: 'dedicated_nuban',
      amount: 1500000, // 15,000 Naira
      reference: 'mock_tx_' + Date.now(),
      customer: {
        customer_code: 'CUS_ho5i4emlxg7b1mp'
      }
    }
  };

  const rawBody = JSON.stringify(payload);
  const hash = crypto.createHmac('sha512', SECRET_KEY).update(rawBody).digest('hex');

  try {
    console.log('Sending mock webhook...');
    const res = await axios.post(webhookUrl, rawBody, {
      headers: {
        'Content-Type': 'application/json',
        'x-paystack-signature': hash
      }
    });
    console.log('Webhook sent successfully!', res.status);
  } catch (err) {
    console.error('Error:', err.message);
  }
}

simulate();
