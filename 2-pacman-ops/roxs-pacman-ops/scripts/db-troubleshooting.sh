#!/bin/bash

# 🔧 Database Health Check & Troubleshooting Script
# 90DaysWithRoxs DevOps Challenge

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${CYAN}=====================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}=====================================${NC}"
}

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
    echo "🔧 Database Health Check & Troubleshooting - Pacman DevOps Challenge"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Health Check Commands:"
    echo "  health               🏥 Complete health check of all databases"
    echo "  mongo-health         🍃 MongoDB specific health check"
    echo "  redis-health         ⚡ Redis specific health check"
    echo ""
    echo "Troubleshooting Commands:"
    echo "  fix-connections      🔗 Fix common connection issues"
    echo "  clean-cache          🧹 Clean Redis cache and expired sessions"
    echo "  repair-mongodb       🔧 Repair MongoDB issues (DESTRUCTIVE)"
    echo "  analyze-performance  📊 Analyze database performance"
    echo ""
    echo "Monitoring Commands:"
    echo "  live-monitor         📺 Live monitoring dashboard"
    echo "  alerts-check         🚨 Check for system alerts"
    echo "  memory-usage         💾 Check memory usage"
    echo ""
    echo "Maintenance Commands:"
    echo "  cleanup-old-data     🗑️  Clean old scores and inactive users"
    echo "  optimize-indexes     ⚡ Create and optimize database indexes"
    echo "  backup-db           💾 Create backup of databases"
    echo ""
    echo "Examples:"
    echo "  $0 health"
    echo "  $0 live-monitor"
    echo "  $0 clean-cache"
}

# Check if containers are running
check_containers() {
    print_info "Checking container status..."
    
    local mongodb_running=$(docker ps --filter "name=pacman-mongodb" --filter "status=running" -q)
    local redis_running=$(docker ps --filter "name=pacman-redis" --filter "status=running" -q)
    local backend_running=$(docker ps --filter "name=pacman-backend" --filter "status=running" -q)
    
    if [ -z "$mongodb_running" ]; then
        print_error "MongoDB container is not running"
        return 1
    else
        print_success "MongoDB container is running"
    fi
    
    if [ -z "$redis_running" ]; then
        print_error "Redis container is not running"
        return 1
    else
        print_success "Redis container is running"
    fi
    
    if [ -z "$backend_running" ]; then
        print_warning "Backend container is not running"
    else
        print_success "Backend container is running"
    fi
}

# MongoDB health check
mongo_health_check() {
    print_header "MongoDB Health Check"
    
    print_mongo "Testing MongoDB connection..."
    if docker exec pacman-mongodb mongosh --quiet --eval "db.adminCommand('ping').ok" > /dev/null 2>&1; then
        print_success "MongoDB is responding"
    else
        print_error "MongoDB is not responding"
        return 1
    fi
    
    print_mongo "Checking database statistics..."
    docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
        const stats = db.stats();
        print('Database: ' + stats.db);
        print('Collections: ' + stats.collections);
        print('Data Size: ' + Math.round(stats.dataSize / 1024 / 1024 * 100) / 100 + ' MB');
        print('Storage Size: ' + Math.round(stats.storageSize / 1024 / 1024 * 100) / 100 + ' MB');
        print('Indexes: ' + stats.indexes);
        print('Index Size: ' + Math.round(stats.indexSize / 1024 / 1024 * 100) / 100 + ' MB');
    "
    
    print_mongo "Checking collections..."
    docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
        const users = db.users.countDocuments();
        const scores = db.scores.countDocuments();
        print('Users: ' + users);
        print('Scores: ' + scores);
        
        if (users === 0) print('WARNING: No users found');
        if (scores === 0) print('WARNING: No scores found');
    "
    
    print_mongo "Checking indexes..."
    docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
        print('Users indexes: ' + db.users.getIndexes().length);
        print('Scores indexes: ' + db.scores.getIndexes().length);
    "
}

# Redis health check
redis_health_check() {
    print_header "Redis Health Check"
    
    print_redis "Testing Redis connection..."
    if docker exec pacman-redis redis-cli ping > /dev/null 2>&1; then
        print_success "Redis is responding"
    else
        print_error "Redis is not responding"
        return 1
    fi
    
    print_redis "Checking Redis info..."
    docker exec pacman-redis redis-cli info server | grep -E "(redis_version|process_id|uptime_in_seconds)"
    
    print_redis "Checking memory usage..."
    docker exec pacman-redis redis-cli info memory | grep -E "(used_memory_human|maxmemory_human|maxmemory_policy)"
    
    print_redis "Checking connected clients..."
    docker exec pacman-redis redis-cli info clients | grep connected_clients
    
    print_redis "Checking keyspace..."
    docker exec pacman-redis redis-cli info keyspace
    
    print_redis "Checking active sessions..."
    local sessions=$(docker exec pacman-redis redis-cli eval "return #redis.call('keys', 'session:*')" 0)
    print_info "Active sessions: $sessions"
    
    print_redis "Checking leaderboard..."
    local leaderboard_size=$(docker exec pacman-redis redis-cli zcard leaderboard:global 2>/dev/null || echo "0")
    print_info "Leaderboard entries: $leaderboard_size"
}

# Complete health check
complete_health_check() {
    print_header "Complete Database Health Check"
    
    check_containers || return 1
    echo ""
    mongo_health_check
    echo ""
    redis_health_check
    echo ""
    
    print_header "Performance Summary"
    analyze_performance_brief
}

# Fix common connection issues
fix_connections() {
    print_header "Fixing Connection Issues"
    
    print_info "Restarting database containers..."
    docker compose restart pacman-mongodb pacman-redis
    
    print_info "Waiting for services to be ready..."
    sleep 5
    
    print_info "Testing connections..."
    if mongo_health_check > /dev/null 2>&1; then
        print_success "MongoDB connection fixed"
    else
        print_error "MongoDB still has issues"
    fi
    
    if redis_health_check > /dev/null 2>&1; then
        print_success "Redis connection fixed"
    else
        print_error "Redis still has issues"
    fi
}

# Clean Redis cache
clean_cache() {
    print_header "Cleaning Redis Cache"
    
    print_redis "Cleaning expired sessions..."
    docker exec pacman-redis redis-cli eval "
        local keys = redis.call('keys', 'session:*')
        local expired = 0
        for i=1,#keys do
            if redis.call('ttl', keys[i]) == -1 then
                redis.call('del', keys[i])
                expired = expired + 1
            end
        end
        return expired
    " 0
    
    print_redis "Cleaning old leaderboard entries..."
    # Clean weekly leaderboards older than 4 weeks
    for i in {5..52}; do
        local week_key="leaderboard:weekly:$(date -d "$i weeks ago" +%Y-%U 2>/dev/null || echo "old")"
        docker exec pacman-redis redis-cli del "$week_key" > /dev/null 2>&1 || true
    done
    
    print_redis "Optimizing memory..."
    docker exec pacman-redis redis-cli memory purge > /dev/null 2>&1 || true
    
    print_success "Cache cleaning completed"
}

# Repair MongoDB (DESTRUCTIVE)
repair_mongodb() {
    print_header "MongoDB Repair (DESTRUCTIVE OPERATION)"
    
    print_warning "This operation may cause data loss!"
    print_warning "Make sure you have a backup before proceeding."
    
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Operation cancelled"
        return 0
    fi
    
    print_mongo "Stopping backend to prevent new connections..."
    docker compose stop pacman-backend
    
    print_mongo "Running MongoDB repair..."
    docker exec pacman-mongodb mongosh --quiet --eval "db.runCommand({repairDatabase: 1})"
    
    print_mongo "Checking database integrity..."
    docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
        db.users.validate({full: true});
        db.scores.validate({full: true});
    "
    
    print_mongo "Restarting backend..."
    docker compose start pacman-backend
    
    print_success "MongoDB repair completed"
}

# Analyze performance
analyze_performance() {
    print_header "Database Performance Analysis"
    
    print_mongo "MongoDB Performance:"
    docker exec pacman-mongodb mongosh --quiet --eval "
        const status = db.serverStatus();
        print('Uptime: ' + Math.round(status.uptime / 3600) + ' hours');
        print('Current connections: ' + status.connections.current + '/' + status.connections.available);
        print('Memory resident: ' + status.mem.resident + 'MB');
        print('Memory virtual: ' + status.mem.virtual + 'MB');
        print('Operations per second:');
        print('  Queries: ' + (status.opcounters.query || 0));
        print('  Inserts: ' + (status.opcounters.insert || 0));
        print('  Updates: ' + (status.opcounters.update || 0));
        print('  Deletes: ' + (status.opcounters.delete || 0));
    "
    
    print_mongo "Slow operations (if any):"
    docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
        const slowOps = db.currentOp({'secs_running': {\$gte: 5}});
        if (slowOps.inprog.length === 0) {
            print('No slow operations detected');
        } else {
            printjson(slowOps);
        }
    "
    
    print_redis "Redis Performance:"
    docker exec pacman-redis redis-cli info stats | grep -E "(instantaneous_ops_per_sec|total_commands_processed|total_connections_received|keyspace_hits|keyspace_misses)"
    
    print_redis "Redis memory analysis:"
    docker exec pacman-redis redis-cli memory stats | head -20
}

# Brief performance analysis
analyze_performance_brief() {
    print_mongo "MongoDB: $(docker exec pacman-mongodb mongosh --quiet --eval "db.serverStatus().connections.current") connections, $(docker exec pacman-mongodb mongosh --quiet --eval "db.serverStatus().mem.resident")MB RAM"
    
    print_redis "Redis: $(docker exec pacman-redis redis-cli info clients | grep connected_clients | cut -d: -f2 | tr -d '\r') clients, $(docker exec pacman-redis redis-cli info memory | grep used_memory_human | cut -d: -f2 | tr -d '\r') RAM"
}

# Live monitoring
live_monitor() {
    print_header "Live Database Monitoring"
    print_info "Press Ctrl+C to stop monitoring"
    
    while true; do
        clear
        echo "🎮 PACMAN DEVOPS - Database Live Monitor"
        echo "$(date)"
        echo ""
        
        # Health status
        echo "🏥 Health Status:"
        if docker exec pacman-mongodb mongosh --quiet --eval "db.adminCommand('ping').ok" > /dev/null 2>&1; then
            echo -e "MongoDB: ${GREEN}✅ UP${NC}"
        else
            echo -e "MongoDB: ${RED}❌ DOWN${NC}"
        fi
        
        if docker exec pacman-redis redis-cli ping > /dev/null 2>&1; then
            echo -e "Redis: ${GREEN}✅ UP${NC}"
        else
            echo -e "Redis: ${RED}❌ DOWN${NC}"
        fi
        
        echo ""
        
        # Quick stats
        echo "📊 Quick Stats:"
        analyze_performance_brief
        
        echo ""
        echo "👥 User Activity:"
        docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
            const total = db.users.countDocuments();
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const activeToday = db.scores.distinct('username', {date: {\$gte: today}}).length;
            print('Total Users: ' + total);
            print('Active Today: ' + activeToday);
        " 2>/dev/null || echo "Unable to fetch user stats"
        
        echo ""
        echo "🏆 Recent Scores:"
        docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
            db.scores.find().sort({date: -1}).limit(3).forEach(doc => 
                print(doc.username + ': ' + doc.score + ' (' + doc.date.toISOString().substr(11, 8) + ')')
            );
        " 2>/dev/null || echo "Unable to fetch recent scores"
        
        echo ""
        echo "⚡ Redis Sessions:"
        local sessions=$(docker exec pacman-redis redis-cli eval "return #redis.call('keys', 'session:*')" 0 2>/dev/null || echo "0")
        echo "Active Sessions: $sessions"
        
        sleep 5
    done
}

# Check alerts
check_alerts() {
    print_header "System Alerts Check"
    
    local alerts=0
    
    # Check Redis memory
    local redis_memory=$(docker exec pacman-redis redis-cli info memory | grep used_memory: | cut -d: -f2 | tr -d '\r')
    local max_memory=268435456  # 256MB
    
    if [ "$redis_memory" -gt "$max_memory" ]; then
        print_error "Redis memory usage high: $(($redis_memory / 1048576))MB"
        alerts=$((alerts + 1))
    fi
    
    # Check MongoDB connections
    local mongo_connections=$(docker exec pacman-mongodb mongosh --quiet --eval "db.serverStatus().connections.current" 2>/dev/null || echo "0")
    if [ "$mongo_connections" -gt 50 ]; then
        print_error "MongoDB connections high: $mongo_connections"
        alerts=$((alerts + 1))
    fi
    
    # Check disk space
    local disk_usage=$(docker exec pacman-mongodb df /data/db | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        print_error "MongoDB disk usage high: $disk_usage%"
        alerts=$((alerts + 1))
    fi
    
    # Check for long-running operations
    local slow_ops=$(docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "db.currentOp({'secs_running': {\$gte: 10}}).inprog.length" 2>/dev/null || echo "0")
    if [ "$slow_ops" -gt 0 ]; then
        print_error "Slow MongoDB operations detected: $slow_ops"
        alerts=$((alerts + 1))
    fi
    
    if [ "$alerts" -eq 0 ]; then
        print_success "No alerts found - system is healthy"
    else
        print_warning "Total alerts: $alerts"
    fi
}

# Memory usage analysis
memory_usage() {
    print_header "Memory Usage Analysis"
    
    print_mongo "MongoDB Memory:"
    docker exec pacman-mongodb mongosh --quiet --eval "
        const status = db.serverStatus();
        print('Resident: ' + status.mem.resident + 'MB');
        print('Virtual: ' + status.mem.virtual + 'MB');
        print('Mapped: ' + (status.mem.mapped || 'N/A') + 'MB');
    "
    
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" pacman-mongodb pacman-redis pacman-backend 2>/dev/null || echo "Unable to get container stats"
    
    print_redis "Redis Memory:"
    docker exec pacman-redis redis-cli info memory | grep -E "(used_memory_human|used_memory_peak_human|maxmemory_human)"
    
    print_redis "Top Redis keys by memory:"
    docker exec pacman-redis redis-cli eval "
        local keys = redis.call('keys', '*')
        local result = {}
        for i=1,math.min(#keys, 10) do
            local size = redis.call('memory', 'usage', keys[i])
            table.insert(result, keys[i] .. ': ' .. size .. ' bytes')
        end
        return result
    " 0 2>/dev/null || echo "Unable to analyze Redis key memory"
}

# Cleanup old data
cleanup_old_data() {
    print_header "Cleaning Up Old Data"
    
    print_warning "This will delete old scores and inactive users"
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Operation cancelled"
        return 0
    fi
    
    print_mongo "Cleaning old scores (older than 1 year)..."
    docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
        const oneYearAgo = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000);
        const result = db.scores.deleteMany({date: {\$lt: oneYearAgo}});
        print('Deleted ' + result.deletedCount + ' old scores');
    "
    
    print_mongo "Finding inactive users (no scores in 6 months)..."
    docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
        const sixMonthsAgo = new Date(Date.now() - 6 * 30 * 24 * 60 * 60 * 1000);
        const activeUsers = db.scores.distinct('username', {date: {\$gte: sixMonthsAgo}});
        const inactiveResult = db.users.deleteMany({
            username: {\$nin: activeUsers},
            registrationDate: {\$lt: sixMonthsAgo}
        });
        print('Deleted ' + inactiveResult.deletedCount + ' inactive users');
    "
    
    print_redis "Cleaning expired Redis keys..."
    clean_cache
    
    print_success "Cleanup completed"
}

# Optimize indexes
optimize_indexes() {
    print_header "Optimizing Database Indexes"
    
    print_mongo "Creating optimized indexes..."
    docker exec pacman-mongodb mongosh --quiet pacman-devops --eval "
        // User indexes
        db.users.createIndex({username: 1}, {unique: true, background: true});
        db.users.createIndex({email: 1}, {unique: true, background: true});
        db.users.createIndex({team: 1, 'stats.bestScore': -1}, {background: true});
        
        // Score indexes
        db.scores.createIndex({username: 1, date: -1}, {background: true});
        db.scores.createIndex({score: -1, date: -1}, {background: true});
        db.scores.createIndex({date: -1}, {background: true});
        
        // Text search index
        try {
            db.users.createIndex({username: 'text', fullName: 'text'}, {background: true});
        } catch(e) {
            print('Text index already exists or failed: ' + e.message);
        }
        
        print('Index optimization completed');
        print('Users indexes: ' + db.users.getIndexes().length);
        print('Scores indexes: ' + db.scores.getIndexes().length);
    "
    
    print_success "Index optimization completed"
}

# Create backup
backup_db() {
    print_header "Creating Database Backup"
    
    local backup_dir="/tmp/pacman-backup-$(date +%Y%m%d-%H%M%S)"
    
    print_info "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    
    print_mongo "Backing up MongoDB..."
    docker exec pacman-mongodb mongodump --db pacman-devops --out /tmp/backup
    docker cp pacman-mongodb:/tmp/backup/pacman-devops "$backup_dir/mongodb"
    
    print_redis "Backing up Redis..."
    docker exec pacman-redis redis-cli SAVE
    docker cp pacman-redis:/data/dump.rdb "$backup_dir/redis-dump.rdb"
    
    print_info "Compressing backup..."
    tar -czf "$backup_dir.tar.gz" -C "$backup_dir" .
    rm -rf "$backup_dir"
    
    print_success "Backup created: $backup_dir.tar.gz"
    print_info "Backup size: $(du -h "$backup_dir.tar.gz" | cut -f1)"
}

# Main script logic
case "${1:-help}" in
    "help"|"--help"|"-h")
        show_help
        ;;
    "health")
        complete_health_check
        ;;
    "mongo-health")
        mongo_health_check
        ;;
    "redis-health")
        redis_health_check
        ;;
    "fix-connections")
        fix_connections
        ;;
    "clean-cache")
        clean_cache
        ;;
    "repair-mongodb")
        repair_mongodb
        ;;
    "analyze-performance")
        analyze_performance
        ;;
    "live-monitor")
        live_monitor
        ;;
    "alerts-check")
        check_alerts
        ;;
    "memory-usage")
        memory_usage
        ;;
    "cleanup-old-data")
        cleanup_old_data
        ;;
    "optimize-indexes")
        optimize_indexes
        ;;
    "backup-db")
        backup_db
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
