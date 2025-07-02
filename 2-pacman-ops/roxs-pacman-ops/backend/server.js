const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const os = require('os');

const app = express();
const port = process.env.PORT || 8080;

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

let users = [];
let scores = [];
let participants = [];

const getContainerInfo = () => {
  return {
    platform: process.env.KUBERNETES_SERVICE_HOST ? 'Kubernetes' : 'Docker',
    hostname: os.hostname(),
    environment: process.env.NODE_ENV || 'development',
    nodeInfo: {
      os: os.platform(),
      arch: os.arch(),
      version: process.version
    },
    containerRuntime: 'docker',
    timestamp: new Date().toISOString()
  };
};

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/ready', (req, res) => {
  res.json({ status: 'ready', timestamp: new Date().toISOString() });
});

app.get('/container-info', (req, res) => {
  res.json(getContainerInfo());
});

app.post('/users', (req, res) => {
  const userData = {
    id: users.length + 1,
    ...req.body,
    createdAt: new Date().toISOString(),
    containerInfo: getContainerInfo()
  };
  
  users.push(userData);
  
  if (userData.isParticipant) {
    participants.push(userData);
  }
  
  console.log(`New user registered: ${userData.username} (Participant: ${userData.isParticipant})`);
  res.status(201).json({ message: 'User created successfully', userId: userData.id });
});

app.post('/auth', (req, res) => {
  const { username, password } = req.body;
  const user = users.find(u => u.username === username);
  
  if (user && user.password === password) {
    const mockToken = `mock-jwt-token-${user.id}-${Date.now()}`;
    console.log(`User authenticated: ${username}`);
    res.json({
      token: mockToken,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        fullName: user.fullName
      }
    });
  } else {
    res.status(401).json({ message: 'Invalid credentials' });
  }
});

app.get('/auth', (req, res) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader) {
    return res.status(401).json({ message: 'No token provided' });
  }
  
  if (authHeader.startsWith('mock-jwt-token-')) {
    // Extract user ID from mock token
    const tokenParts = authHeader.split('-');
    const userId = parseInt(tokenParts[3]);
    const user = users.find(u => u.id === userId);
    
    if (user) {
      console.log(`Token verified for user: ${user.username}`);
      res.json({ 
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          fullName: user.fullName
        }
      });
    } else {
      res.status(401).json({ message: 'Invalid token' });
    }
  } else {
    res.status(401).json({ message: 'Invalid token format' });
  }
});

// Scores
app.get('/scores', (req, res) => {
  // Mock scores if empty
  if (scores.length === 0) {
    scores = [
      { username: 'roxsross', points: 5500 },
      { username: 'devops_hero', points: 4200 },
      { username: 'k8s_master', points: 3800 },
      { username: 'docker_ninja', points: 3400 },
      { username: 'cloud_warrior', points: 2900 }
    ];
  }
  
  res.json({ scores: scores.slice(0, 10) });
});

app.post('/scores', (req, res) => {
  const scoreData = {
    id: scores.length + 1,
    ...req.body,
    timestamp: new Date().toISOString(),
    containerInfo: getContainerInfo()
  };
  
  scores.push(scoreData);
  scores.sort((a, b) => b.score - a.score); // Sort by score descending
  
  console.log(`New score: ${scoreData.username} - ${scoreData.score} points`);
  res.status(201).json({ message: 'Score saved successfully' });
});

// Participants
app.get('/participants', (req, res) => {
  // Add mock participants if empty
  if (participants.length === 0) {
    participants = [
      {
        username: 'roxsross',
        fullName: 'Rossana Ross',
        email: 'roxsross@devops.com',
        team: 'DevOps Masters',
        registrationDate: new Date().toISOString(),
        gameStats: {
          gamesPlayed: 15,
          highScore: 5500,
          totalScore: 45000,
          victories: 5,
          achievements: ['first-win', 'high-scorer', 'speed-demon']
        },
        containerInfo: {
          platform: 'Kubernetes',
          hostname: 'k8s-master-01',
          environment: 'production'
        }
      },
      {
        username: 'devops_hero',
        fullName: 'DevOps Hero',
        email: 'hero@devops.com',
        team: 'Cloud Warriors',
        registrationDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
        gameStats: {
          gamesPlayed: 8,
          highScore: 4200,
          totalScore: 18500,
          victories: 2,
          achievements: ['first-win', 'team-player']
        },
        containerInfo: {
          platform: 'Docker',
          hostname: 'docker-host-01',
          environment: 'staging'
        }
      }
    ];
  }
  
  res.json({ participants });
});

// Container stats
app.get('/container-stats', (req, res) => {
  const stats = {
    totalGames: scores.length,
    totalParticipants: participants.length,
    avgScore: scores.length > 0 ? Math.round(scores.reduce((acc, s) => acc + (s.score || s.points), 0) / scores.length) : 0,
    topScore: scores.length > 0 ? Math.max(...scores.map(s => s.score || s.points)) : 0,
    platformDistribution: {
      'Kubernetes': Math.floor(participants.length * 0.6),
      'Docker': Math.floor(participants.length * 0.3),
      'Bare Metal': Math.floor(participants.length * 0.1)
    },
    lastUpdated: new Date().toISOString()
  };
  
  res.json(stats);
});

// Live stats
app.get('/live-stats', (req, res) => {
  res.json({
    onlinePlayers: Math.floor(Math.random() * 50) + 10, // Mock online players
    gamesInProgress: Math.floor(Math.random() * 15) + 5, // Mock games in progress
    timestamp: new Date().toISOString()
  });
});

// User rank
app.get('/user-rank/:username', (req, res) => {
  const { username } = req.params;
  const sortedScores = [...scores].sort((a, b) => (b.score || b.points) - (a.score || a.points));
  const userIndex = sortedScores.findIndex(s => s.username === username);
  
  res.json({
    position: userIndex + 1,
    total: sortedScores.length,
    username
  });
});

// Generic error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    message: 'Endpoint not found', 
    info: 'This is a placeholder backend. Implement the full backend for production use.',
    availableEndpoints: [
      'GET /health',
      'GET /ready', 
      'GET /container-info',
      'POST /users',
      'POST /auth',
      'GET /scores',
      'POST /scores',
      'GET /participants',
      'GET /container-stats',
      'GET /live-stats',
      'GET /user-rank/:username'
    ]
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Pacman DevOps Challenge - Backend Placeholder`);
  console.log(`📡 Server running on port ${port}`);
  console.log(`🐳 Platform: ${getContainerInfo().platform}`);
  console.log(`🏠 Hostname: ${getContainerInfo().hostname}`);
  console.log(`⚡ Environment: ${process.env.NODE_ENV}`);
  console.log(`🎯 Challenge: ${process.env.CHALLENGE_NAME}`);
  console.log(`📊 Ready to receive DevOps Challenge data!`);
  console.log(`\n🔗 Available endpoints:`);
  console.log(`   GET  /health - Health check`);
  console.log(`   GET  /container-info - Container information`);
  console.log(`   POST /users - Register users/participants`);
  console.log(`   POST /auth - Authenticate users`);
  console.log(`   GET  /scores - Get high scores`);
  console.log(`   POST /scores - Save new scores`);
  console.log(`   GET  /participants - Get challenge participants`);
  console.log(`   GET  /container-stats - Get challenge statistics`);
  console.log(`   GET  /live-stats - Get live statistics`);
  console.log(`\n💡 This is a placeholder. Implement the full backend with MongoDB/Redis for production!`);
});
