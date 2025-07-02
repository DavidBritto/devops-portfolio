db = db.getSiblingDB('pacman-devops');

db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["username", "password", "registrationDate"],
      properties: {
        username: {
          bsonType: "string",
          minLength: 3,
          maxLength: 15,
          description: "Username must be 3-15 characters"
        },
        password: {
          bsonType: "string",
          description: "Hashed password"
        },
        email: {
          bsonType: "string",
          pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
          description: "Valid email address"
        },
        fullName: {
          bsonType: "string",
          description: "Full name of the participant"
        },
        team: {
          bsonType: "string",
          description: "Team name"
        },
        isParticipant: {
          bsonType: "bool",
          description: "Whether user is a DevOps challenge participant"
        },
        containerInfo: {
          bsonType: "object",
          properties: {
            platform: { bsonType: "string" },
            hostname: { bsonType: "string" },
            environment: { bsonType: "string" }
          }
        },
        registrationDate: {
          bsonType: "date",
          description: "User registration date"
        },
        devOpsChallenge: {
          bsonType: "string",
          description: "Challenge identifier"
        },
        gameStats: {
          bsonType: "object",
          properties: {
            gamesPlayed: { bsonType: "int", minimum: 0 },
            highScore: { bsonType: "int", minimum: 0 },
            totalScore: { bsonType: "int", minimum: 0 },
            victories: { bsonType: "int", minimum: 0 },
            achievements: { bsonType: "array", items: { bsonType: "string" } }
          }
        }
      }
    }
  }
});

db.createCollection('scores', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["username", "score", "gameDate"],
      properties: {
        username: {
          bsonType: "string",
          description: "Player username"
        },
        score: {
          bsonType: "int",
          minimum: 0,
          description: "Game score"
        },
        gameDate: {
          bsonType: "date",
          description: "When the game was played"
        },
        gameDuration: {
          bsonType: "int",
          minimum: 0,
          description: "Game duration in seconds"
        },
        level: {
          bsonType: "int",
          minimum: 1,
          description: "Level reached"
        },
        isVictory: {
          bsonType: "bool",
          description: "Whether the game was completed successfully"
        },
        containerInfo: {
          bsonType: "object",
          properties: {
            platform: { bsonType: "string" },
            hostname: { bsonType: "string" },
            environment: { bsonType: "string" }
          }
        }
      }
    }
  }
});

db.createCollection('gameSessions', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["username", "sessionStart"],
      properties: {
        username: { bsonType: "string" },
        sessionStart: { bsonType: "date" },
        sessionEnd: { bsonType: "date" },
        finalScore: { bsonType: "int", minimum: 0 },
        levelsCompleted: { bsonType: "int", minimum: 0 },
        pellets: { bsonType: "int", minimum: 0 },
        powerUps: { bsonType: "int", minimum: 0 },
        ghosts: { bsonType: "int", minimum: 0 },
        containerInfo: { bsonType: "object" }
      }
    }
  }
});

// Create indexes for better performance
db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "email": 1 }, { unique: true, sparse: true });
db.users.createIndex({ "isParticipant": 1 });
db.users.createIndex({ "registrationDate": 1 });
db.users.createIndex({ "gameStats.highScore": -1 });
db.users.createIndex({ "containerInfo.platform": 1 });

db.scores.createIndex({ "username": 1 });
db.scores.createIndex({ "score": -1 });
db.scores.createIndex({ "gameDate": -1 });
db.scores.createIndex({ "username": 1, "gameDate": -1 });

db.gameSessions.createIndex({ "username": 1 });
db.gameSessions.createIndex({ "sessionStart": -1 });
db.gameSessions.createIndex({ "finalScore": -1 });

// Insert sample data for testing
db.users.insertMany([
  {
    username: "roxsross",
    password: "$2b$10$example_hashed_password", // This should be properly hashed
    email: "roxsross@devops.com",
    fullName: "Rossana Ross",
    team: "DevOps Masters",
    isParticipant: true,
    containerInfo: {
      platform: "Kubernetes",
      hostname: "k8s-master-01",
      environment: "production"
    },
    registrationDate: new Date(),
    devOpsChallenge: "90DaysWithRoxs",
    gameStats: {
      gamesPlayed: 15,
      highScore: 5500,
      totalScore: 45000,
      victories: 5,
      achievements: ["first-win", "high-scorer", "speed-demon"]
    }
  },
  {
    username: "devops_hero",
    password: "$2b$10$example_hashed_password2",
    email: "hero@devops.com",
    fullName: "DevOps Hero",
    team: "Cloud Warriors",
    isParticipant: true,
    containerInfo: {
      platform: "Docker",
      hostname: "docker-host-01",
      environment: "staging"
    },
    registrationDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
    devOpsChallenge: "90DaysWithRoxs",
    gameStats: {
      gamesPlayed: 8,
      highScore: 3200,
      totalScore: 18500,
      victories: 2,
      achievements: ["first-win", "team-player"]
    }
  }
]);

// Insert sample scores
db.scores.insertMany([
  {
    username: "roxsross",
    score: 5500,
    gameDate: new Date(),
    gameDuration: 450,
    level: 8,
    isVictory: true,
    containerInfo: {
      platform: "Kubernetes",
      hostname: "k8s-master-01",
      environment: "production"
    }
  },
  {
    username: "devops_hero",
    score: 3200,
    gameDate: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
    gameDuration: 320,
    level: 5,
    isVictory: false,
    containerInfo: {
      platform: "Docker",
      hostname: "docker-host-01",
      environment: "staging"
    }
  }
]);

// Create user for the application
db.createUser({
  user: "pacman_app",
  pwd: "pacman_app_password",
  roles: [
    {
      role: "readWrite",
      db: "pacman-devops"
    }
  ]
});