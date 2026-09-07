const http = require('http');

async function test() {
  const req = http.request({
    hostname: 'localhost',
    port: 3001,
    path: '/api/v1/auth/login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      const { accessToken } = JSON.parse(data);
      if (!accessToken) {
        console.error('No access token', data);
        return;
      }

      // getMe
      http.request({
        hostname: 'localhost',
        port: 3001,
        path: '/api/v1/auth/me',
        method: 'GET',
        headers: { 'Authorization': 'Bearer ' + accessToken }
      }, (res2) => {
        let meData = '';
        res2.on('data', chunk => meData += chunk);
        res2.on('end', () => {
          const user = JSON.parse(meData);
          console.log('GET /auth/me:', user);

          // getEntitlement
          http.request({
            hostname: 'localhost',
            port: 3001,
            path: '/api/v1/billing/entitlement/' + user.organizationId,
            method: 'GET',
            headers: { 'Authorization': 'Bearer ' + accessToken }
          }, (res3) => {
            let entData = '';
            res3.on('data', chunk => entData += chunk);
            res3.on('end', () => {
              console.log('GET /billing/entitlement STATUS:', res3.statusCode);
              console.log('GET /billing/entitlement BODY:', entData);
            });
          }).end();
        });
      }).end();
    });
  });

  req.write(JSON.stringify({ email: 'abc@mandap.fake', password: 'password123' }));
  req.end();
}

test();
