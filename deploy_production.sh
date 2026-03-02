#!/bin/bash

# Production Deployment Script for Fertility Services Platform
# Usage: ./deploy_production.sh

set -e  # Exit on any error

echo "🚀 Production Deployment Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    print_status "Creating .env file from template..."
    cp env.example .env
    print_warning "Please edit .env file with your production values before continuing!"
    print_status "Key things to update:"
    echo "  - Database credentials"
    echo "  - Payment gateway API keys"
    echo "  - Secret keys"
    echo "  - Domain names"
    echo "  - SSL certificates"
    exit 1
fi

# Load environment variables
print_status "Loading environment variables..."
source .env

# Check prerequisites
print_status "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed!"
    exit 1
fi

# Check if running as root (for port 80/443)
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root - this is required for ports 80/443"
else
    print_warning "Not running as root - some ports may be restricted"
fi

print_status "Prerequisites check passed!"

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p nginx/ssl
mkdir -p nginx/conf.d
mkdir -p logs
mkdir -p uploads

# Set proper permissions
chmod 755 uploads
chmod 600 .env

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down --remove-orphans

# Build and start services
print_status "Building and starting services..."
docker-compose --profile production up -d --build

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Run database migration
print_status "Running database migration..."
docker-compose exec backend python migrate_database.py

# Run database seeding
print_status "Seeding database with initial data..."
docker-compose exec backend python seed_data_standalone.py

# Check service health
print_status "Checking service health..."
docker-compose ps

# Test API endpoints
print_status "Testing API endpoints..."
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    print_status "✅ Backend API is healthy"
else
    print_error "❌ Backend API health check failed"
fi

if curl -f http://localhost:8501 > /dev/null 2>&1; then
    print_status "✅ Admin Dashboard is accessible"
else
    print_error "❌ Admin Dashboard is not accessible"
fi

# Display deployment information
echo ""
echo "🎉 Production deployment completed!"
echo "=================================="
echo ""
echo "Services running:"
echo "  - Backend API: http://localhost:${API_PORT:-8000}"
echo "  - Admin Dashboard: http://localhost:${ADMIN_PORT:-8501}"
echo "  - API Documentation: http://localhost:${API_PORT:-8000}/docs"
echo ""
echo "Database:"
echo "  - Host: ${DB_HOST:-localhost}"
echo "  - Port: ${DB_PORT:-3307}"
echo "  - Database: ${DB_NAME:-fertility_services}"
echo ""
echo "Default credentials:"
echo "  - Admin: ${ADMIN_EMAIL:-admin@fertilityservices.com} / ${ADMIN_PASSWORD:-admin123}"
echo "  - Patient: patient1@example.com / password123"
echo ""
echo "Next steps:"
echo "  1. Configure your domain in nginx/conf.d/"
echo "  2. Add SSL certificates to nginx/ssl/"
echo "  3. Update payment gateway API keys in .env"
echo "  4. Set up monitoring and backups"
echo "  5. Configure firewall rules"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop services: docker-compose down"
echo "  - Restart services: docker-compose restart"
echo "  - Update services: docker-compose pull && docker-compose up -d"
echo ""
