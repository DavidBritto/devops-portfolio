#!/bin/bash

# 🗃️ Database Query Helper Script
# 90DaysWithRoxs DevOps Challenge

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_mongo() {
    echo -e "${PURPLE}[MONGODB]${NC} $1"
}

print_redis() {
    echo -e "${YELLOW}[REDIS]${NC} $1"
}

# Help function
show_help() {
    echo "🗃️ Database Query Helper - Pacman DevOps Challenge"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "MongoDB Commands:"
    echo "  mongo-stats          📊 Show MongoDB statistics"
    echo "  mongo-users          👤 List all users"
    echo "  mongo-scores         🏆 Show top 10 scores"
    echo "  mongo-leaderboard    📈 Display leaderboard"
    echo "  mongo-backup         💾 Create MongoDB backup"
    echo ""
    echo "Redis Commands:"
    echo "  redis-stats          📊 Show Redis statistics"
    echo "  redis-leaderboard    🏆 Show Redis leaderboard"
    echo "  redis-sessions       🔑 List active sessions"
    echo "  redis-cache          📦 Show cache statistics"
    echo "  redis-backup         💾 Create Redis backup"
    echo ""
    echo "Monitoring Commands:"
    echo "  monitor-all          👁️  Monitor both databases"
    echo "  health-check         💓 Check database health"
    echo "  clean-expired        🧹 Clean expired data"
    echo ""
    echo "Examples:"
    echo "  $0 mongo-leaderboard     # Show MongoDB leaderboard"
    echo "  $0 redis-stats           # Show Redis statistics"
    echo "  $0 monitor-all           # Monitor both databases"
    echo ""
}

# Check if containers are running
check_containers() {
    if ! docker ps | grep -q "pacman-mongodb"; then
        print_error "MongoDB container is not running!"
        exit 1
    fi
    
    if ! docker ps | grep -q "pacman-redis"; then
        print_error "Redis container is not running!"
        exit 1
    fi
}

# MongoDB Functions
mongo_stats() {
    print_mongo "Getting MongoDB statistics..."
    docker exec pacman-mongodb mongosh pacman-devops --quiet --eval "
        print('=== DATABASE STATS ===');
        printjson(db.stats());
        print('\\n=== COLLECTIONS ===');
        db.getCollectionNames().forEach(function(collection) {
            print(collection + ': ' + db[collection].countDocuments() + ' documents');
        });
    "
}

mongo_users() {
    print_mongo "Listing MongoDB users..."
    docker exec pacman-mongodb mongosh pacman-devops --quiet --eval "
        print('=== RECENT USERS ===');
        db.users.find({}, {username: 1, fullName: 1, team: 1, registrationDate: 1, 'stats.bestScore': 1})
               .sort({registrationDate: -1})
               .limit(10)
               .forEach(printjson);
    "
}

mongo_scores() {
    print_mongo "Getting top 10 scores from MongoDB..."
    docker exec pacman-mongodb mongosh pacman-devops --quiet --eval "
        print('=== TOP 10 SCORES ===');
        db.scores.find({}, {username: 1, score: 1, level: 1, gameTime: 1, timestamp: 1})
                 .sort({score: -1})
                 .limit(10)
                 .forEach(printjson);
    "
}

mongo_leaderboard() {
    print_mongo "Generating MongoDB leaderboard..."
    docker exec pacman-mongodb mongosh pacman-devops --quiet --eval "
        print('=== LEADERBOARD (Best Scores) ===');
        db.users.aggregate([
            {\$match: {'stats.totalGames': {\$gte: 1}}},
            {\$project: {
                username: 1,
                fullName: 1,
                team: 1,
                bestScore: '\$stats.bestScore',
                totalGames: '\$stats.totalGames',
                averageScore: '\$stats.averageScore'
            }},
            {\$sort: {bestScore: -1}},
            {\$limit: 15}
        ]).forEach(printjson);
    "
}

mongo_backup() {
    print_mongo "Creating MongoDB backup..."
    DATE=$(date +%Y%m%d_%H%M%S)
    docker exec pacman-mongodb mongodump --db pacman-devops --out /tmp/backup_$DATE
    print_success "MongoDB backup created in container: /tmp/backup_$DATE"
}

# Redis Functions
redis_stats() {
    print_redis "Getting Redis statistics..."
    echo "=== REDIS INFO ==="
    docker exec pacman-redis redis-cli INFO server | grep -E "(redis_version|uptime_in_seconds|process_id)"
    echo ""
    echo "=== MEMORY USAGE ==="
    docker exec pacman-redis redis-cli INFO memory | grep -E "(used_memory_human|maxmemory_human|used_memory_peak_human)"
    echo ""
    echo "=== STATS ==="
    docker exec pacman-redis redis-cli INFO stats | grep -E "(total_commands_processed|total_connections_received|keyspace_hits|keyspace_misses)"
    echo ""
    echo "=== DATABASE SIZE ==="
    echo "Total keys: $(docker exec pacman-redis redis-cli DBSIZE)"
}

redis_leaderboard() {
    print_redis "Getting Redis leaderboard..."
    echo "=== GLOBAL LEADERBOARD (Top 10) ==="
    docker exec pacman-redis redis-cli ZREVRANGE global_leaderboard 0 9 WITHSCORES
    echo ""
    echo "=== DAILY LEADERBOARD (Top 5) ==="
    docker exec pacman-redis redis-cli ZREVRANGE leaderboard:daily 0 4 WITHSCORES
}

redis_sessions() {
    print_redis "Listing active Redis sessions..."
    echo "=== ACTIVE SESSIONS ==="
    docker exec pacman-redis redis-cli KEYS "session:*" | head -10
    echo ""
    echo "=== ONLINE USERS ==="
    docker exec pacman-redis redis-cli SMEMBERS online_users
}

redis_cache() {
    print_redis "Getting Redis cache statistics..."
    echo "=== CACHE KEYS ==="
    docker exec pacman-redis redis-cli KEYS "cache:*" | head -10
    echo ""
    echo "=== USER CACHE SAMPLE ==="
    USER_CACHE=$(docker exec pacman-redis redis-cli KEYS "cache:user:*" | head -1)
    if [ ! -z "$USER_CACHE" ]; then
        docker exec pacman-redis redis-cli GET "$USER_CACHE"
    fi
}

redis_backup() {
    print_redis "Creating Redis backup..."
    docker exec pacman-redis redis-cli BGSAVE
    print_success "Redis backup initiated (background save)"
}

# Monitoring Functions
monitor_all() {
    print_info "Starting database monitoring..."
    echo ""
    
    while true; do
        clear
        echo "🗃️ PACMAN DEVOPS - DATABASE MONITOR"
        echo "=================================="
        echo "Time: $(date)"
        echo ""
        
        # MongoDB Stats
        print_mongo "MongoDB Status"
        MONGO_CONNECTIONS=$(docker exec pacman-mongodb mongosh --quiet --eval "db.serverStatus().connections.current" 2>/dev/null || echo "Error")
        MONGO_DOCS=$(docker exec pacman-mongodb mongosh pacman-devops --quiet --eval "db.users.countDocuments() + db.scores.countDocuments()" 2>/dev/null || echo "Error")
        echo "  Connections: $MONGO_CONNECTIONS"
        echo "  Total Documents: $MONGO_DOCS"
        
        echo ""
        
        # Redis Stats
        print_redis "Redis Status"
        REDIS_MEMORY=$(docker exec pacman-redis redis-cli INFO memory | grep used_memory_human | cut -d: -f2 | tr -d '\r' 2>/dev/null || echo "Error")
        REDIS_KEYS=$(docker exec pacman-redis redis-cli DBSIZE 2>/dev/null || echo "Error")
        REDIS_CLIENTS=$(docker exec pacman-redis redis-cli INFO clients | grep connected_clients | cut -d: -f2 | tr -d '\r' 2>/dev/null || echo "Error")
        echo "  Memory: $REDIS_MEMORY"
        echo "  Keys: $REDIS_KEYS"
        echo "  Clients: $REDIS_CLIENTS"
        
        echo ""
        echo "Press Ctrl+C to exit monitoring..."
        sleep 5
    done
}

health_check() {
    print_info "Performing database health check..."
    
    # MongoDB Health
    print_mongo "Checking MongoDB health..."
    if docker exec pacman-mongodb mongosh --quiet --eval "db.adminCommand('ismaster')" >/dev/null 2>&1; then
        print_success "MongoDB is healthy ✅"
    else
        print_error "MongoDB is unhealthy ❌"
    fi
    
    # Redis Health
    print_redis "Checking Redis health..."
    if docker exec pacman-redis redis-cli ping | grep -q "PONG"; then
        print_success "Redis is healthy ✅"
    else
        print_error "Redis is unhealthy ❌"
    fi
}

clean_expired() {
    print_info "Cleaning expired data..."
    
    # MongoDB cleanup
    print_mongo "Cleaning expired MongoDB sessions..."
    docker exec pacman-mongodb mongosh pacman-devops --quiet --eval "
        var result = db.sessions.deleteMany({expiresAt: {\$lt: new Date()}});
        print('Deleted ' + result.deletedCount + ' expired sessions');
    "
    
    # Redis cleanup (Redis handles TTL automatically, but we can check)
    print_redis "Checking Redis expired keys..."
    EXPIRED_COUNT=$(docker exec pacman-redis redis-cli EVAL "
        local expired = 0
        for i=1,1000 do
            local key = redis.call('RANDOMKEY')
            if key and redis.call('TTL', key) == -1 then
                expired = expired + 1
            end
        end
        return expired
    " 0)
    echo "Estimated keys without TTL: $EXPIRED_COUNT"
    
    print_success "Cleanup completed!"
}

# Main script logic
case "${1:-help}" in
    mongo-stats)
        check_containers
        mongo_stats
        ;;
    mongo-users)
        check_containers
        mongo_users
        ;;
    mongo-scores)
        check_containers
        mongo_scores
        ;;
    mongo-leaderboard)
        check_containers
        mongo_leaderboard
        ;;
    mongo-backup)
        check_containers
        mongo_backup
        ;;
    redis-stats)
        check_containers
        redis_stats
        ;;
    redis-leaderboard)
        check_containers
        redis_leaderboard
        ;;
    redis-sessions)
        check_containers
        redis_sessions
        ;;
    redis-cache)
        check_containers
        redis_cache
        ;;
    redis-backup)
        check_containers
        redis_backup
        ;;
    monitor-all)
        check_containers
        monitor_all
        ;;
    health-check)
        check_containers
        health_check
        ;;
    clean-expired)
        check_containers
        clean_expired
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
