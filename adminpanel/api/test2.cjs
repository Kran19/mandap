const { PrismaClient } = require('@prisma/client');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const http = require('http');

const prisma = new PrismaClient();

async function main() {
  const user = await prisma.user.findFirst({
    where: { email: { startsWith: 'abc' } },
    include: { organizations: true }
  });

  if (!user) {
    console.error('User not found');
    return;
  }

  const payload = { sub: user.id };
  const accessToken = jwt.sign(payload, process.env.JWT_ACCESS_SECRET || 'secret123', { expiresIn: '1h' });
  console.log('User ID:', user.id);
  console.log('Org ID:', user.organizations[0].organizationId);

  const req = http.request({
    hostname: 'localhost',
    port: 3001,
    path: '/api/v1/billing/entitlement/' + user.organizations[0].organizationId,
    method: 'GET',
    headers: { 'Authorization': 'Bearer ' + accessToken }
  }, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      console.log('STATUS:', res.statusCode);
      console.log('BODY:', data);
    });
  });

  req.end();
}

main().catch(console.error).finally(() => prisma.$disconnect());
