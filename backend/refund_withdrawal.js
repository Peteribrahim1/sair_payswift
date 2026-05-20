const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: 'postgresql://sair_db_user:l1q8IYoI1tkx5vUOqrO7aiXs4URtIXHA@dpg-d85ievog4nts7381ia40-a/sair_db',
    },
  },
});

async function main() {
  // Find the most recent WITHDRAWAL transaction
  const lastWithdrawal = await prisma.transaction.findFirst({
    where: { type: 'WITHDRAWAL' },
    orderBy: { createdAt: 'desc' },
    include: { user: true },
  });

  if (!lastWithdrawal) {
    console.log('No withdrawal transactions found.');
    return;
  }

  console.log(`\nFound last withdrawal:`);
  console.log(`  User    : ${lastWithdrawal.user.email}`);
  console.log(`  Amount  : ₦${lastWithdrawal.amount}`);
  console.log(`  Date    : ${lastWithdrawal.createdAt}`);
  console.log(`  Status  : ${lastWithdrawal.status}`);
  console.log(`  Ref     : ${lastWithdrawal.reference || 'N/A'}\n`);

  // Refund the amount to the user's wallet
  await prisma.$transaction([
    prisma.user.update({
      where: { id: lastWithdrawal.userId },
      data: { balance: { increment: lastWithdrawal.amount } },
    }),
    prisma.transaction.update({
      where: { id: lastWithdrawal.id },
      data: { status: 'REFUNDED' },
    }),
    prisma.notification.create({
      data: {
        userId: lastWithdrawal.userId,
        title: 'Withdrawal Reversed',
        message: `₦${lastWithdrawal.amount.toFixed(2)} has been refunded to your wallet. We apologise for the inconvenience.`,
      },
    }),
  ]);

  const updatedUser = await prisma.user.findUnique({ where: { id: lastWithdrawal.userId } });
  console.log(`✅ Successfully refunded ₦${lastWithdrawal.amount} to ${lastWithdrawal.user.email}`);
  console.log(`   New wallet balance: ₦${updatedUser?.balance}`);
}

main()
  .catch((e) => {
    console.error('Error:', e.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
