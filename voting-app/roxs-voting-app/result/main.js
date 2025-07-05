const express = require('express');
const path = require('path');
const async = require('async');
const { Pool } = require('pg');
const cookieParser = require('cookie-parser');
const app = express();
const server = require('http').Server(app);
const io = require('socket.io')(server);
const prometheus = require('prom-client');

// Collect default metrics (CPU, Memory, etc.)
prometheus.collectDefaultMetrics({
  timeout: 5000,
  gcDurationBuckets: [0.001, 0.01, 0.1, 1, 2, 5],
});

// Define custom Prometheus metrics
const httpRequestCounter = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5]
});

const activeConnections = new prometheus.Gauge({
  name: 'websocket_connections_active',
  help: 'Number of active WebSocket connections'
});

const dbConnectionStatus = new prometheus.Gauge({
  name: 'database_connection_status',
  help: 'Database connection status (1 = connected, 0 = disconnected)'
});

const totalVotes = new prometheus.Gauge({
  name: 'votes_in_database_total',
  help: 'Total number of votes stored in database'
});

const votesByOption = new prometheus.Gauge({
  name: 'votes_by_option',
  help: 'Number of votes by option',
  labelNames: ['option']
});

// Middleware to track HTTP requests
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const labels = {
      method: req.method,
      route: req.route ? req.route.path : req.path,
      status_code: res.statusCode
    };
    
    httpRequestCounter.inc(labels);
    httpRequestDuration.observe(labels, duration);
  });
  
  next();
});

// Define a route to expose Prometheus metrics
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', prometheus.register.contentType);
    const metrics = await prometheus.register.metrics();
    res.end(metrics);
  } catch (error) {
    console.error('Error serving metrics:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Health check endpoint
app.get('/healthz', (req, res) => {
  res.status(200).json({ 
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'result-service'
  });
});

// Loading environment variables
const port = process.env.APP_PORT || 3000;
const dbhost = process.env.DATABASE_HOST || 'database';
const dbname = process.env.DATABASE_NAME || 'votes';
const dbuser = process.env.DATABASE_USER || 'postgres';
const dbpass = process.env.DATABASE_PASSWORD || 'postgres';

if (!dbhost) {
  throw new Error("DATABASE_HOST not set");
}

if (!dbname) {
  throw new Error("DATABASE_NAME not set");
}

const connectionString = `postgres://${dbuser}:${dbpass}@${dbhost}/${dbname}`;

// Track WebSocket connections
let connectionCount = 0;

io.on('connection', function (socket) {
  connectionCount++;
  activeConnections.set(connectionCount);
  
  socket.emit('message', { text : 'Welcome!' });

  socket.on('subscribe', function (data) {
    socket.join(data.channel);
  });
  
  socket.on('disconnect', function() {
    connectionCount--;
    activeConnections.set(connectionCount);
  });
});

const pool = new Pool({
  connectionString: connectionString,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Function to ensure votes table exists
async function ensureVotesTable(client) {
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS votes (
        id VARCHAR(255) PRIMARY KEY,
        vote VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log("Tabla 'votes' asegurada en result");
    dbConnectionStatus.set(1);
  } catch (err) {
    console.error("Error creando tabla votes:", err);
    dbConnectionStatus.set(0);
  }
}

// Database connection with retry logic
async.retry(
  {times: 1000, interval: 1000},
  function(callback) {
    pool.connect(function(err, client, done) {
      if (err) {
        console.error("Waiting for db");
        dbConnectionStatus.set(0);
      } else {
        dbConnectionStatus.set(1);
      }
      callback(err, client);
    });
  },
  async function(err, client) {
    if (err) {
      console.error("Giving up");
      dbConnectionStatus.set(0);
      return;
    }
    console.log("Connected to db");
    dbConnectionStatus.set(1);
    await ensureVotesTable(client);
    getVotes(client);
  }
);

function getVotes(client) {
  client.query('SELECT vote, COUNT(id) AS count FROM votes GROUP BY vote', [], function(err, result) {
    if (err) {
      console.error("Error performing query: " + err);
      dbConnectionStatus.set(0);
    } else {
      dbConnectionStatus.set(1);
      var votes = collectVotesFromResult(result);
      
      // Update Prometheus metrics
      const total = votes.a + votes.b;
      totalVotes.set(total);
      votesByOption.set({ option: 'a' }, votes.a);
      votesByOption.set({ option: 'b' }, votes.b);
      
      // Emit to WebSocket clients
      io.sockets.emit("scores", JSON.stringify(votes));
    }

    setTimeout(function() { getVotes(client) }, 1000);
  });
}

function collectVotesFromResult(result) {
  var votes = {a: 0, b: 0};

  result.rows.forEach(function (row) {
    votes[row.vote] = parseInt(row.count);
  });

  return votes;
}

app.use(cookieParser());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(__dirname + '/views'));

app.get('/', function (req, res) {
  const filePath = path.resolve(__dirname + '/views/index.html');
  res.sendFile(filePath, (err) => {
    if (err) {
      console.error('Error serving index.html:', err);
      res.status(404).send('File not found');
    }
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
    process.exit(0);
  });
});

server.listen(port, function () {
  var port = server.address().port;
  console.log('App running on port ' + port);
});