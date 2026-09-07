const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function updatePlans() {
  await prisma.plan.updateMany({
    where: { monthlyProviderPlanId: null },
    data: { monthlyProviderPlanId: 'plan_mock_monthly' }
  });
  console.log('Updated plans');
}

updatePlans().finally(() => prisma.$disconnect());
