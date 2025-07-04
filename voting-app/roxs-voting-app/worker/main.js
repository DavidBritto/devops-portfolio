const { Client } = require("pg");
const Redis = require("ioredis");
const dns = require("dns");
const { register, collectDefaultMetrics } = require('prom-client');
const express = require('express');

const app = express();
const port = 3001;

collectDefaultMetrics();

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Configuración mejorada de timeouts
const DB_CONFIG = {
  host: process.env.DATABASE_HOST || "database",
  user: process.env.DATABASE_USER || "postgres",
  password: process.env.DATABASE_PASSWORD || "postgres",
  database: process.env.DATABASE_NAME || "votes",
  connectionTimeoutMillis: 10000,
  idleTimeoutMillis: 30000,
  query_timeout: 10000,
};

const REDIS_CONFIG = {
  host: null, // Se establecerá dinámicamente
  port: 6379,
  connectTimeout: 10000,
  lazyConnect: true,
  retryDelayOnFailover: 100,
  maxRetriesPerRequest: 3,
};

async function openDbConnection(connectionOptions) {
  let pgClient;

  while (true) {
    try {
      pgClient = new Client(connectionOptions);
      await pgClient.connect();
      break;
    } catch (error) {
      if (error.code === "ECONNREFUSED") {
        console.log("Waiting for DB");
        await sleep(2000);
      } else {
        console.log("Error connecting to DB:", error.message);
        await sleep(2000);
      }
    }
  }

  console.log("Connected to DB");

  try {
    await pgClient.query(`
      CREATE TABLE IF NOT EXISTS votes (
        id VARCHAR(255) PRIMARY KEY,
        vote VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log("Database table ensured");
  } catch (error) {
    console.log("Error creating table:", error.message);
  }

  return pgClient;
}

async function openRedisConnection() {
  let hostname = process.env.REDIS_HOST || "redis";

  while (true) {
    try {
      const ipAddress = await getIP(hostname);
      console.log(`Found Redis at ${ipAddress}`);

      const redisConfig = { ...REDIS_CONFIG, host: ipAddress };
      const redisClient = new Redis(redisConfig);

      // Configurar manejadores de eventos
      redisClient.on('error', (err) => {
        console.log('Redis connection error:', err.message);
      });

      redisClient.on('connect', () => {
        console.log('Redis connected');
      });

      redisClient.on('ready', () => {
        console.log('Redis ready');
      });

      redisClient.on('close', () => {
        console.log('Redis connection closed');
      });

      await redisClient.ping();
      console.log("Connected to Redis successfully");

      return redisClient;
    } catch (error) {
      console.log("Waiting for Redis:", error.message);
      await sleep(2000);
    }
  }
}

async function getIP(hostname) {
  return new Promise((resolve, reject) => {
    dns.lookup(hostname, { family: 4 }, (err, address) => {
      if (err) {
        reject(err);
      } else {
        resolve(address);
      }
    });
  });
}

async function updateVote(client, voterID, vote) {
  const queryInsert =
    "INSERT INTO votes (id, vote) VALUES ($1, $2) ON CONFLICT (id) DO UPDATE SET vote = $2, created_at = CURRENT_TIMESTAMP";

  try {
    const result = await client.query(queryInsert, [voterID, vote]);
    console.log(`Vote updated for voter ${voterID}: ${vote}`);
    return result;
  } catch (error) {
    console.log("Error updating vote:", error.message);
    throw error;
  }
}

// Routes para el worker
app.get('/', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    service: 'vote-worker',
    metrics_path: '/metrics' 
  });
});

app.get('/metrics', async (req, res) => {
  try {
    const metrics = await register.metrics();
    res.set('Content-Type', register.contentType);
    res.end(metrics);
  } catch (error) {
    console.error('Error exporting metrics:', error);
    res.status(500).send('Error exporting metrics');
  }
});

app.get('/healthz', (req, res) => {
  res.status(200).json({ 
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'vote-worker'
  });
});

const main = async () => {
  let pgClient;
  let redisClient;

  try {
    // Inicializar conexiones
    pgClient = await openDbConnection(DB_CONFIG);
    redisClient = await openRedisConnection();

    const keepAliveCommand = "SELECT 1";
    let consecutiveErrors = 0;
    const MAX_CONSECUTIVE_ERRORS = 5;

    console.log("Vote processing worker started");

    while (true) {
      try {
        await sleep(100);

        // Verificar conexión Redis
        if (redisClient.status !== 'ready') {
          console.log("Redis not ready, attempting to reconnect...");
          await redisClient.connect();
          continue;
        }

        // Procesar voto desde Redis
        const data = await redisClient.lpop("votes");

        if (data !== null) {
          try {
            const voteData = JSON.parse(data);
            console.log(
              `Processing vote for '${voteData.vote}' by '${voteData.voter_id}'`
            );

            // Verificar conexión DB
            try {
              await pgClient.query(keepAliveCommand);
            } catch (error) {
              console.log("DB connection lost, reconnecting...");
              await pgClient.end();
              pgClient = await openDbConnection(DB_CONFIG);
            }

            // Actualizar voto
            await updateVote(pgClient, voteData.voter_id, voteData.vote);
            consecutiveErrors = 0; // Reset error counter en caso de éxito

          } catch (error) {
            console.log("Error processing vote:", error.message);
            consecutiveErrors++;
            
            if (consecutiveErrors >= MAX_CONSECUTIVE_ERRORS) {
              console.log("Too many consecutive errors, restarting connections...");
              throw error;
            }
          }
        } else {
          // Keep alive para PostgreSQL cuando no hay votos
          try {
            await pgClient.query(keepAliveCommand);
          } catch (error) {
            console.log("DB keep-alive failed, reconnecting...");
            await pgClient.end();
            pgClient = await openDbConnection(DB_CONFIG);
          }
        }
      } catch (error) {
        console.log("Main loop error:", error.message);
        
        // Reiniciar conexiones si hay demasiados errores
        try {
          if (pgClient) await pgClient.end();
          if (redisClient) await redisClient.quit();
        } catch (cleanupError) {
          console.log("Error during cleanup:", cleanupError.message);
        }

        // Reintento con backoff exponencial
        await sleep(Math.min(5000, 1000 * Math.pow(2, consecutiveErrors)));
        
        // Reinicializar conexiones
        pgClient = await openDbConnection(DB_CONFIG);
        redisClient = await openRedisConnection();
        consecutiveErrors = 0;
      }
    }
  } catch (error) {
    console.error("Fatal error in main:", error);
    process.exit(1);
  }
};

// Manejo de señales para cierre limpio
process.on('SIGINT', async () => {
  console.log('Received SIGINT, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Received SIGTERM, shutting down gracefully...');
  process.exit(0);
});

// Iniciar worker
main().catch((error) => {
  console.error("Failed to start worker:", error);
  process.exit(1);
});

// Iniciar servidor de métricas
app.listen(port, () => {
  console.log(`Worker metrics server listening at http://0.0.0.0:${port}`);
});
