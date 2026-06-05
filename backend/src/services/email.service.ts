// This service is currently mocked to log OTPs to the console.
// Once you provide SMTP credentials, you can replace this with nodemailer.

export const sendPasswordResetEmail = async (email: string, otp: string) => {
  console.log(`\n=========================================`);
  console.log(`📧 MOCK EMAIL SENT TO: ${email}`);
  console.log(`🔑 PASSWORD RESET OTP: ${otp}`);
  console.log(`=========================================\n`);
  
  // Example of how it will look later:
  // const transporter = nodemailer.createTransport({ ... });
  // await transporter.sendMail({
  //   from: '"Sair PaySwift" <noreply@sairpayswift.com>',
  //   to: email,
  //   subject: 'Password Reset OTP',
  //   text: `Your password reset OTP is ${otp}. It expires in 15 minutes.`,
  // });
};
