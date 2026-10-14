import http from 'k6/http';
import { check, sleep } from 'k6';

// Stress test: Buscar el punto de quiebre del cluster
export const options = {
  stages: [
    { duration: '30s', target: 50 },  // Carga moderada
    { duration: '1m', target: 150 },  // Carga pesada
    { duration: '1m', target: 300 },  // Carga al limite
    { duration: '30s', target: 0 },   // Recuperacion
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'], // Maximo 5% de error en punto de estres
  },
};

export default function () {
  const url = 'http://localhost:5000/';
  const options = ['a', 'b'];
  const voteChoice = options[Math.floor(Math.random() * options.length)];
  const payload = `vote=${voteChoice}`;

  const res = http.post(url, payload, {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });

  check(res, {
    'status es 200': (r) => r.status === 200,
  });

  sleep(0.5);
}
