import axios from 'axios';
import { prisma } from '../prisma';

export class AirtimeCashService {
  /**
   * Mocks initializing an Airtime to Cash transaction with a 3rd party provider.
   */
  static async initializeConversion(amount: number, network: string, phone: string, userId: string): Promise<any> {
    const reference = `AC-${Date.now()}-${Math.floor(Math.random() * 10000)}`;
    
    // Get dynamic payout rate
    let payoutRate = 70.0;
    const config = await prisma.appConfig.findUnique({ where: { id: 'global-config' } });
    if (config) payoutRate = config.airtimeToCashRate;

    const payout = amount * (payoutRate / 100);

    // Create a pending transaction in our database
    const transaction = await prisma.transaction.create({
      data: {
        userId,
        type: 'CONVERT_AIRTIME',
        amount: payout, // The amount they will receive
        status: 'PENDING',
        network,
        phone,
        reference
      }
    });

    try {
      // Map network
      let cheetahNetwork = network.toUpperCase();
      if (cheetahNetwork === 'MTN') cheetahNetwork = 'MTN TRANSFER';
      if (cheetahNetwork === '9MOBILE') cheetahNetwork = '9 MOBILE';

      // Send to CheetahPay
      const payload = new URLSearchParams();
      payload.append('amount', amount.toString());
      payload.append('private_key', process.env.CHEETAHPAY_PRIVATE_KEY || '');
      payload.append('public_key', process.env.CHEETAHPAY_PUBLIC_KEY || '');
      payload.append('phone', phone.startsWith('+234') ? '0' + phone.slice(4) : phone);
      payload.append('network', cheetahNetwork);
      payload.append('order_id', reference);

      const response = await axios.post('https://cheetahpay.com.ng/api/v1', payload.toString(), {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      });

      const data = response.data;
      if (data && data.success === false) {
        throw new Error(data.message || 'CheetahPay rejected the request');
      }

      // If it's successful, CheetahPay returns the transfer instructions in the message or specific fields
      // Typically it returns {"success": true, "message": "Please transfer 1000 to 08011...", "data": ...}
      // If the message is missing, we'll provide a generic fallback
      const instructions = data.message || `Transfer ₦${amount} ${cheetahNetwork} airtime to the number provided by CheetahPay.\n\nYour wallet will be credited automatically once received.`;

      return {
        success: true,
        reference,
        instructions,
        payout,
        transactionId: transaction.id
      };
    } catch (e: any) {
      console.error("CheetahPay Error:", e.response?.data || e.message);
      
      // Update transaction status to failed
      await prisma.transaction.update({
        where: { id: transaction.id },
        data: { status: 'FAILED' }
      });

      return {
        success: false,
        error: e.response?.data?.message || e.message || 'Failed to initialize with provider'
      };
    }
  }

  /**
   * Handles the webhook callback from the 3rd party provider
   */
  static async handleWebhook(payload: any) {
    console.log('CheetahPay Webhook received:', payload);
    
    // Log exactly what CheetahPay sent us to the database for debugging
    try {
      await prisma.webhookLog.create({
        data: {
          provider: 'CheetahPay',
          payload: JSON.stringify(payload)
        }
      });
    } catch (e) {
      console.error('Failed to save webhook log:', e);
    }

    // CheetahPay might send status, status_code, order_id, transaction_id, etc.
    const reference = payload.order_id || payload.reference;
    // Usually 'success' or 'credited' depending on the API. 
    // We will assume any status that indicates success like 'success', 'credited', 'successful'
    const statusStr = (payload.status || '').toString().toLowerCase();
    const isSuccess = statusStr === 'success' || statusStr === 'credited' || statusStr === 'successful';

    if (!isSuccess) {
      return { success: false, message: 'Transaction failed or rejected by provider' };
    }

    // Find the pending transaction
    const transaction = await prisma.transaction.findFirst({
      where: { reference, status: 'PENDING' }
    });

    if (!transaction) {
      return { success: false, message: 'Transaction not found or already processed' };
    }

    // Process the payout
    await prisma.$transaction([
      // Update transaction status
      prisma.transaction.update({
        where: { id: transaction.id },
        data: { status: 'COMPLETED' }
      }),
      // Credit user's wallet
      prisma.user.update({
        where: { id: transaction.userId },
        data: { balance: { increment: transaction.amount } }
      }),
      // Send a notification
      prisma.notification.create({
        data: {
          userId: transaction.userId,
          title: 'Airtime Converted',
          message: `Your airtime to cash conversion of ₦${transaction.amount} was successful.`,
          read: false
        }
      })
    ]);

    return { success: true };
  }
}
