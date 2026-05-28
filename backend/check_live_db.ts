import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: "postgresql://sair_db_user:l1q8IYoI1tkx5vUOqrO7aiXs4URtIXHA@dpg-d85ievog4nts7381ia40-a.oregon-postgres.render.com/sair_db",
    },
  },
});

async function main() {
  const txs = await prisma.transaction.findMany({
    where: { type: 'CONVERT_AIRTIME' },
    orderBy: { createdAt: 'desc' },
    take: 5
  });
  console.log("Recent CONVERT_AIRTIME transactions:");
  console.log(JSON.stringify(txs, null, 2));
}

main().catch(console.error).finally(() => prisma.$disconnect());
