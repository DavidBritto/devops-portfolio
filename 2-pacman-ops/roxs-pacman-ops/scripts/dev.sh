#!/bin/bash

# 🎮 Pacman DevOps Challenge - Development Script
# 90DaysWithRoxs Challenge

set -e


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

print_status() {
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

show_help() {
    echo "🎮 Pacman DevOps Challenge - Development Helper"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start         🚀 Start all services with Docker Compose"
    echo "  stop          ⏹️  Stop all services"
    echo "  restart       🔄 Restart all services"
    echo "  build         🏗️  Build all images"
    echo "  logs          📋 Show logs from all services"
    echo "  clean         🧹 Clean up containers, networks, and volumes"
    echo "  dev-frontend  💻 Start frontend development server"
    echo "  dev-backend   ⚙️  Start backend development server"
    echo "  test          🧪 Run tests"
    echo "  health        💓 Check services health"
    echo "  setup         📦 Initial project setup"
    echo "  help          ❓ Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start              # Start all services"
    echo "  $0 logs frontend      # Show frontend logs"
    echo "  $0 dev-frontend       # Start frontend in dev mode"
    echo ""
}

start_services() {
    print_status "Starting Pacman DevOps Challenge services..."
    docker compose up -d --build
    print_success "Services started! 🚀"
    echo ""
    echo "📱 URLs:"
    echo "   🎮 Game:         http://localhost:8000"
    echo "   🔧 API:          http://localhost:8080"
    echo "   📊 Mongo Express: http://localhost:8081"
    echo "   💻 Health:       http://localhost:8080/health"
}


stop_services() {
    print_status "Stopping services..."
    docker compose down
    print_success "Services stopped! ⏹️"
}


restart_services() {
    print_status "Restarting services..."
    docker compose down
    docker compose up -d --build
    print_success "Services restarted! 🔄"
}


build_images() {
    print_status "Building images..."
    docker compose build
    print_success "Images built! 🏗️"
}


show_logs() {
    if [ -n "$2" ]; then
        print_status "Showing logs for $2..."
        docker compose logs -f "$2"
    else
        print_status "Showing logs for all services..."
        docker compose logs -f
    fi
}


clean_up() {
    print_warning "This will remove all containers, networks, and volumes!"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up..."
        docker compose down -v
        docker system prune -f
        print_success "Cleanup completed! 🧹"
    else
        print_status "Cleanup cancelled."
    fi
}


dev_frontend() {
    print_status "Starting frontend development server..."
    cd frontend
    if [ ! -d "node_modules" ]; then
        print_status "Installing dependencies..."
        npm install
    fi
    npm start
}


dev_backend() {
    print_status "Starting backend development server..."
    cd backend
    if [ ! -d "node_modules" ]; then
        print_status "Installing dependencies..."
        npm install
    fi
    npm run dev
}


run_tests() {
    print_status "Running tests..."
    cd frontend
    npm test -- --coverage --watchAll=false
    cd ../backend
    npm test
    print_success "Tests completed! 🧪"
}


check_health() {
    print_status "Checking services health..."
    

    if docker compose ps | grep -q "Up"; then
        print_success "Docker services are running ✅"
        

        if curl -s http://localhost:8000 > /dev/null; then
            print_success "Frontend is healthy ✅"
        else
            print_error "Frontend is not responding ❌"
        fi
        

        if curl -s http://localhost:8080/health > /dev/null; then
            print_success "Backend is healthy ✅"
        else
            print_error "Backend is not responding ❌"
        fi
        

        if docker compose exec -T mongodb mongosh --eval "db.adminCommand('ismaster')" > /dev/null 2>&1; then
            print_success "MongoDB is healthy ✅"
        else
            print_error "MongoDB is not responding ❌"
        fi
        
    else
        print_error "Docker services are not running ❌"
        print_status "Run '$0 start' to start services"
    fi
}

# Initial setup
setup_project() {
    print_status "Setting up Pacman DevOps Challenge..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_status "Installing frontend dependencies..."
    cd frontend && npm install && cd ..
    
    print_status "Installing backend dependencies..."
    cd backend && npm install && cd ..
    
    print_success "Project setup completed! 📦"
    print_status "Run '$0 start' to start the services"
}

# Main script logic
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    build)
        build_images
        ;;
    logs)
        show_logs "$@"
        ;;
    clean)
        clean_up
        ;;
    dev-frontend)
        dev_frontend
        ;;
    dev-backend)
        dev_backend
        ;;
    test)
        run_tests
        ;;
    health)
        check_health
        ;;
    setup)
        setup_project
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
