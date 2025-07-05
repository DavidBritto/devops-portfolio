import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.6.0/index.js';
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";

// =============================================================================
// 🗳️ RoxsRoss Voting - K6 Load Test OPTIMIZADO
// =============================================================================

// Métricas personalizadas
const votesSuccessful = new Counter('votes_successful_total');
const votesRejected = new Counter('votes_rejected_total');
const votingSuccessRate = new Rate('voting_success_rate');
const cookieValidation = new Rate('cookie_validation_success');

// Configuración del test
export const options = {
  scenarios: {
    unique_voters: {
      executor: 'per-vu-iterations',
      vus: 100,
      iterations: 1,
      maxDuration: '3m',
      tags: { test_type: 'unique_voters' },
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    http_req_failed: ['rate<0.1'],
    voting_success_rate: ['rate>0.90'],
    cookie_validation_success: ['rate>0.95'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  noConnectionReuse: false,
  userAgent: 'K6-RoxsRossVoting/1.0',
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const VOTE_ENDPOINT = `${BASE_URL}/`;
const STATS_ENDPOINT = `${BASE_URL}/stats`;
const VOTE_OPTIONS = ['a', 'b'];

export function setup() {
  console.log('🚀 Iniciando test de votación RoxsRoss...');
  const healthCheck = http.get(BASE_URL);
  if (healthCheck.status !== 200) {
    throw new Error(`❌ Endpoint no accesible: ${BASE_URL} (Status: ${healthCheck.status})`);
  }
  let initialStats = { total_votes: 0, cats_votes: 0, dogs_votes: 0 };
  try {
    const statsResponse = http.get(STATS_ENDPOINT);
    if (statsResponse.status === 200) {
      initialStats = JSON.parse(statsResponse.body);
      console.log(`📊 Estado inicial: ${initialStats.total_votes} votos, ` +
                 `${initialStats.cats_votes} gatos, ${initialStats.dogs_votes} perros`);
    }
  } catch (e) {
    console.warn('⚠️ No se pudieron obtener estadísticas iniciales');
  }
  console.log(`🎯 Endpoint: ${BASE_URL}`);
  console.log(`🗳️ Opciones: ${initialStats.current_options?.option_a || 'Cats'} vs ${initialStats.current_options?.option_b || 'Dogs'}`);
  return { initialStats };
}

export default function(data) {
  const userId = `user_${__VU}_${__ITER}_${randomString(8)}`;
  simulateVoter(userId);
}

function simulateVoter(userId) {
  const visitResponse = http.get(VOTE_ENDPOINT, {
    tags: { action: 'visit_page', user_id: userId }
  });
  const pageLoadSuccess = check(visitResponse, {
    'página principal carga': (r) => r.status === 200,
    'contiene formulario de votación': (r) => r.body.includes('name="vote"'),
    'contiene opciones Cats/Dogs': (r) => r.body.includes('Cats') && r.body.includes('Dogs'),
    'no muestra error': (r) => !r.body.includes('error-message'),
  });
  if (!pageLoadSuccess) {
    console.error(`❌ Usuario ${userId}: Error cargando página`);
    return;
  }
  const cookieHeader = visitResponse.headers['Set-Cookie'];
  const hasCookie = cookieHeader && cookieHeader.includes('voter_id=');
  cookieValidation.add(hasCookie);
  if (hasCookie) {
    console.log(`✅ Usuario ${userId}: Cookie establecida`);
  } else {
    console.warn(`⚠️ Usuario ${userId}: Cookie no establecida`);
  }
  sleep(Math.random() * 4 + 1);
  const voteOption = VOTE_OPTIONS[Math.floor(Math.random() * VOTE_OPTIONS.length)];
  castVote(userId, voteOption);
}

function castVote(userId, voteOption) {
  const voteResponse = http.post(VOTE_ENDPOINT, 
    { vote: voteOption },
    {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': `K6-RoxsRossVoting-${userId}`,
      },
      tags: { 
        action: 'cast_vote',
        user_id: userId,
        vote_option: voteOption,
      }
    }
  );
  const result = {
    success: false,
    error: false,
    message: ''
  };
  const voteChecks = check(voteResponse, {
    'voto procesado (HTTP 200)': (r) => r.status === 200,
    'página de confirmación': (r) => r.body.includes('Gracias') || r.body.includes('registrado'),
    'no error de servidor': (r) => r.status < 500,
    'cookie actualizada': (r) => r.headers['Set-Cookie'] && r.headers['Set-Cookie'].includes('voter_id='),
  });
  if (voteResponse.status === 200 && (voteResponse.body.includes('Gracias') || voteResponse.body.includes('registrado'))) {
    result.success = true;
    result.message = 'Voto registrado exitosamente';
    console.log(`✅ Usuario ${userId}: Voto ${voteOption} registrado`);
  } else {
    result.error = true;
    result.message = `Error HTTP ${voteResponse.status}`;
    console.error(`❌ Usuario ${userId}: Error ${voteResponse.status}`);
  }
  if (result.success) {
    votesSuccessful.add(1);
    votingSuccessRate.add(true);
  } else {
    votesRejected.add(1);
    votingSuccessRate.add(false);
  }
  return result;
}

export function teardown(data) {
  console.log('📊 Finalizando test y analizando resultados...');
  try {
    const finalStatsResponse = http.get(STATS_ENDPOINT);
    if (finalStatsResponse.status === 200) {
      const finalStats = JSON.parse(finalStatsResponse.body);
      const initialStats = data.initialStats || {};
      const initialTotal = initialStats.total_votes || 0;
      const finalTotal = finalStats.total_votes || 0;
      const newVotes = finalTotal - initialTotal;
      const initialCats = initialStats.cats_votes || 0;
      const initialDogs = initialStats.dogs_votes || 0;
      const finalCats = finalStats.cats_votes || 0;
      const finalDogs = finalStats.dogs_votes || 0;
      console.log('\n📈 RESUMEN DE RESULTADOS:');
      console.log(`📊 Votos iniciales: ${initialTotal} (🐱 ${initialCats}, 🐶 ${initialDogs})`);
      console.log(`📊 Votos finales: ${finalTotal} (🐱 ${finalCats}, 🐶 ${finalDogs})`);
      console.log(`✅ Nuevos votos: ${newVotes}`);
      console.log(`🐱 Nuevos votos Cats: ${finalCats - initialCats}`);
      console.log(`🐶 Nuevos votos Dogs: ${finalDogs - initialDogs}`);
      if (newVotes > 0) {
        console.log('🎉 ¡Test exitoso! Los votos se registraron correctamente');
      } else {
        console.warn('⚠️ ADVERTENCIA: No se registraron nuevos votos');
      }
    }
  } catch (e) {
    console.error('❌ Error obteniendo estadísticas finales:', e.message);
  }
  console.log('🏁 Test de votación completado');
}

export function handleSummary(data) {
  const summary = {
    timestamp: new Date().toISOString(),
    test_type: __ENV.TEST_TYPE || 'default',
    endpoint: BASE_URL,
    metrics: {
      total_requests: data.metrics.http_reqs?.values?.count || 0,
      successful_votes: data.metrics.votes_successful_total?.values?.count || 0,
      rejected_votes: data.metrics.votes_rejected_total?.values?.count || 0,
      voting_success_rate: (data.metrics.voting_success_rate?.values?.rate || 0) * 100,
      cookie_validation_rate: (data.metrics.cookie_validation_success?.values?.rate || 0) * 100,
      avg_response_time: data.metrics.http_req_duration?.values?.avg || 0,
      p95_response_time: data.metrics.http_req_duration?.values?.p95 || 0,
      error_rate: (data.metrics.http_req_failed?.values?.rate || 0) * 100
    }
  };

  const textSummary = `
🗳️ ========== REPORTE FINAL ROXSROSS VOTING ==========
📅 Timestamp: ${summary.timestamp}
🎯 Endpoint: ${summary.endpoint}
🔬 Tipo de test: ${summary.test_type}

📊 MÉTRICAS DE VOTACIÓN:
✅ Votos exitosos: ${summary.metrics.successful_votes}
❌ Votos rechazados: ${summary.metrics.rejected_votes}
📈 Tasa de éxito general: ${summary.metrics.voting_success_rate.toFixed(2)}%

🍪 VALIDACIÓN DE COOKIES:
📈 Tasa de cookies válidas: ${summary.metrics.cookie_validation_rate.toFixed(2)}%

⚡ RENDIMIENTO:
📊 Requests totales: ${summary.metrics.total_requests}
📊 Tiempo promedio: ${summary.metrics.avg_response_time.toFixed(2)}ms
📊 P95 tiempo: ${summary.metrics.p95_response_time.toFixed(2)}ms
📊 Tasa de errores: ${summary.metrics.error_rate.toFixed(2)}%

${summary.metrics.voting_success_rate > 90 ? '🎉 ¡TEST EXITOSO!' : '⚠️ Revisar configuración'}
====================================================`;

  return {
    'summary.json': JSON.stringify(summary, null, 2),
    'summary.html': htmlReport(data),
    stdout: textSummary
  };
}