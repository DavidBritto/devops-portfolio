import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 }, // Ramp-up a 20 usuarios virtuales
    { duration: '1m', target: 20 },  // Mantener carga estable
    { duration: '15s', target: 0 },  // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<300'], // 95% de las peticiones deben responder en menos de 300ms
    http_req_failed: ['rate<0.01'],    // Menos de 1% de errores HTTP
  },
};

export default function () {
  const url = 'http://localhost:5000/'; // Endpoint de la app vote
  const payload = 'vote=a';
  const params = {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  };

  const res = http.post(url, payload, params);

  check(res, {
    'status es 200': (r) => r.status === 200,
    'tiempo respuesta < 300ms': (r) => r.timings.duration < 300,
  });

  sleep(1);
}
