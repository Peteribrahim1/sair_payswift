const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: "postgresql://sair_db_user:l1q8IYoI1tkx5vUOqrO7aiXs4URtIXHA@dpg-d85ievog4nts7381ia40-a.oregon-postgres.render.com/sair_db"
    }
  }
});

async function main() {
  console.log("👀 Watching for new transactions for peteribrahim@gmail.com...");
  let lastTxId = null;

  // Get initial latest transaction
  const initial = await prisma.transaction.findFirst({
    where: { user: { email: 'peteribrahim@gmail.com' } },
    orderBy: { createdAt: 'desc' }
  });
  if (initial) {
    lastTxId = initial.id;
    console.log(`Latest existing transaction: ${initial.type} of ${initial.amount} (Ref: ${initial.reference})`);
  }

  setInterval(async () => {
    try {
      const latest = await prisma.transaction.findFirst({
        where: { user: { email: 'peteribrahim@gmail.com' } },
        orderBy: { createdAt: 'desc' }
      });
      if (latest && latest.id !== lastTxId) {
        lastTxId = latest.id;
        console.log(`\n🎉 NEW TRANSACTION DETECTED!`);
        console.log(`Type:      ${latest.type}`);
        console.log(`Network:   ${latest.network || 'N/A'}`);
        console.log(`Amount:    ₦${latest.amount}`);
        console.log(`Phone:     ${latest.phone || 'N/A'}`);
        console.log(`Status:    ${latest.status}`);
        console.log(`Request ID: ${latest.reference}`);
        console.log(`Time:      ${latest.createdAt}`);
      }
    } catch (e) {
      console.error("Error polling database:", e.message);
    }
  }, 2000);
}

main().catch(console.error);
