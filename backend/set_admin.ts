import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const result = await prisma.user.updateMany({
    where: { email: 'peteribrahim@gmail.com' },
    data: { isAdmin: true },
  });
  console.log('✅ Admin flag set:', result);
  await prisma.$disconnect();
}

main().catch(console.error);
