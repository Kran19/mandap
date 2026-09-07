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

  const planId = '687caf22-60f2-4c0e-919f-3c2e9c279e2f'; // Free Plan
  const body = JSON.stringify({
    planId: planId,
    identityReference: 'ababababb',
    idempotencyKey: Date.now().toString()
  });

  const req = http.request({
    hostname: 'localhost',
    port: 3001,
    path: `/api/v1/billing/trial/${user.organizations[0].organizationId}/setup`,
    method: 'POST',
    headers: { 
      'Authorization': 'Bearer ' + accessToken,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body)
    }
  }, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      console.log('STATUS:', res.statusCode);
      console.log('BODY:', data);
    });
  });

  req.write(body);
  req.end();
}

main().catch(console.error).finally(() => prisma.$disconnect());
