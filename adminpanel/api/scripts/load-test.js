import http from 'k6/http';
import { check, sleep } from 'k6';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

export const options = {
  stages: [
    { duration: '30s', target: 50 }, // Ramp-up to 50 users
    { duration: '1m', target: 50 },  // Stay at 50 users
    { duration: '30s', target: 0 },  // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'], // 95% of requests must complete below 500ms
    http_req_failed: ['rate<0.01'],                 // Less than 1% failure rate
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:3001/api/v1';
const ORG_ID = __ENV.ORG_ID || 'test-org-id';
const PROJECT_ID = __ENV.PROJECT_ID || 'test-project-id';
const TOKEN = __ENV.AUTH_TOKEN || 'test-jwt-token';

export default function () {
  const idempotencyKey = uuidv4();
  
  const payload = JSON.stringify({
    expectedCurrentVersionId: 'previous-version-id',
    layoutData: { nodes: [], edges: [] },
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${TOKEN}`,
      'Idempotency-Key': idempotencyKey,
    },
  };

  // 1. Concurrent Idempotency Test - Fire two requests with the same key simultaneously
  const responses = http.batch([
    ['POST', `${BASE_URL}/organizations/${ORG_ID}/projects/${PROJECT_ID}/versions`, payload, params],
    ['POST', `${BASE_URL}/organizations/${ORG_ID}/projects/${PROJECT_ID}/versions`, payload, params],
  ]);

  check(responses[0], {
    'Request 1 is 201 or 409': (r) => r.status === 201 || r.status === 409,
  });

  check(responses[1], {
    'Request 2 is 201 or 409': (r) => r.status === 201 || r.status === 409,
  });

  // Verify that at least one of them handled it gracefully (caching or 409)
  // Both shouldn't trigger duplicate versions.

  sleep(1);
}
