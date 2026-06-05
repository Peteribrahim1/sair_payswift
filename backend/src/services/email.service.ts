import { Resend } from 'resend';

// Initialize the Resend SDK using the API key
const resend = new Resend(process.env.SMTP_PASS);

export const sendPasswordResetEmail = async (email: string, otp: string) => {
  // If no API key is provided, log to console
  if (!process.env.SMTP_PASS) {
    console.log(`\n=========================================`);
    console.log(`📧 MOCK EMAIL SENT TO: ${email}`);
    console.log(`🔑 PASSWORD RESET OTP: ${otp}`);
    console.log(`=========================================\n`);
    return;
  }

  try {
    const { data, error } = await resend.emails.send({
      // The "from" address must be a verified domain on Resend, or onboarding@resend.dev
      from: 'Sair PaySwift <onboarding@resend.dev>',
      to: email,
      subject: 'Password Reset Code - Sair PaySwift',
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #1a1a1a;">Password Reset Request</h2>
          <p>We received a request to reset the password for your Sair PaySwift account.</p>
          <p>Your 4-digit verification code is:</p>
          <h1 style="font-size: 32px; letter-spacing: 5px; color: #4CAF50; background: #f4f4f4; padding: 10px; text-align: center; border-radius: 8px;">${otp}</h1>
          <p>This code will expire in 15 minutes.</p>
          <p>If you did not request this reset, please ignore this email.</p>
        </div>
      `,
    });

    if (error) {
      console.error(`❌ Resend API returned an error:`, error);
      throw new Error(error.message);
    }
    
    console.log(`✅ Real email sent via Resend API to: ${email}`);
  } catch (error) {
    console.error(`❌ Failed to send Resend email:`, error);
    throw error;
  }
};
