const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  await prisma.user.deleteMany({
    where: { email: 'aviralshukla@gmail.com' },
  });
  console.log('Deleted user');
}

main().finally(() => prisma.$disconnect());
