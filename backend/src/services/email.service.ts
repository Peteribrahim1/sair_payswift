import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.resend.com',
  port: Number(process.env.SMTP_PORT) || 465,
  secure: true, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

export const sendPasswordResetEmail = async (email: string, otp: string) => {
  // If no credentials are provided yet, we still log to console for debugging
  if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
    console.log(`\n=========================================`);
    console.log(`📧 MOCK EMAIL SENT TO: ${email}`);
    console.log(`🔑 PASSWORD RESET OTP: ${otp}`);
    console.log(`=========================================\n`);
    return;
  }

  try {
    await transporter.sendMail({
      from: '"Sair PaySwift" <noreply@sairpayswift.com>',
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
    console.log(`✅ Real email sent via SMTP to: ${email}`);
  } catch (error) {
    console.error(`❌ Failed to send SMTP email:`, error);
    throw error;
  }
};
