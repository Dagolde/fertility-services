#!/bin/bash

# Fertility Services App Setup Script
echo "🏥 Setting up Fertility Services Application..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p python_backend/uploads
mkdir -p admin_dashboard/logs
mkdir -p database/backups
mkdir -p nginx/ssl

# Set permissions
chmod +x setup.sh
chmod 755 python_backend/uploads
chmod 755 admin_dashboard/logs

# Copy environment file
echo "⚙️ Setting up environment..."
if [ ! -f python_backend/.env ]; then
    cp python_backend/.env.example python_backend/.env
    echo "✅ Environment file created. Please update python_backend/.env with your settings."
fi

# Build and start services
echo "🐳 Building and starting Docker containers..."
docker-compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Display access information
echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Service Access Information:"
echo "================================"
echo "🔗 Backend API: http://localhost:8000"
echo "📚 API Documentation: http://localhost:8000/docs"
echo "🔧 Admin Dashboard: http://localhost:8501"
echo "🗄️ MySQL Database: localhost:3306"
echo "🔴 Redis Cache: localhost:6379"
echo ""
echo "👤 Default Admin Credentials:"
echo "Email: admin@fertilityservices.com"
echo "Password: admin123"
echo ""
echo "🏥 Sample Hospital Credentials:"
echo "Email: hospital@example.com"
echo "Password: hospital123"
echo ""
echo "👥 Sample User Credentials:"
echo "Patient: patient1@example.com / patient123"
echo "Donor: donor1@example.com / donor123"
echo ""
echo "📱 Flutter App Setup:"
echo "1. Navigate to flutter_app directory"
echo "2. Run: flutter pub get"
echo "3. Run: flutter run"
echo ""
echo "🛠️ Development Commands:"
echo "- View logs: docker-compose logs -f [service_name]"
echo "- Stop services: docker-compose down"
echo "- Restart services: docker-compose restart"
echo "- Update services: docker-compose up -d --build"
echo ""
echo "📖 For more information, check the README.md file"
