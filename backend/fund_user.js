const crypto = require('crypto');
const axios = require('axios');
const dotenv = require('dotenv');
const { PrismaClient } = require('@prisma/client');

dotenv.config();
const prisma = new PrismaClient();

const SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;
const webhookUrl = 'http://localhost:3000/api/wallet/webhook';

async function simulate(email, amountNaira) {
  try {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.paystackCustomerCode) {
      console.error(`User ${email} not found or has no Paystack customer code.`);
      return;
    }

    const payload = {
      event: 'charge.success',
      data: {
        channel: 'dedicated_nuban',
        amount: amountNaira * 100, // Convert to kobo
        reference: 'mock_tx_' + Date.now(),
        customer: {
          customer_code: user.paystackCustomerCode
        }
      }
    };

    const rawBody = JSON.stringify(payload);
    const hash = crypto.createHmac('sha512', SECRET_KEY).update(rawBody).digest('hex');

    console.log(`Sending mock webhook to fund ${email} with ₦${amountNaira}...`);
    const res = await axios.post(webhookUrl, rawBody, {
      headers: {
        'Content-Type': 'application/json',
        'x-paystack-signature': hash
      }
    });
    console.log('Webhook sent successfully!', res.status);
  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    await prisma.$disconnect();
  }
}

const email = process.argv[2];
const amount = parseFloat(process.argv[3]) || 5000;

if (!email) {
  console.log('Usage: node fund_user.js <email> [amount]');
  process.exit(1);
}

simulate(email, amount);
