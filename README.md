# Fertility Services Platform

A comprehensive fertility services platform with mobile app, admin dashboard, and backend API.

## 🚀 Quick Start

### Automated Setup (Recommended)

**Windows:**
```bash
# Command Prompt
setup_complete_system.bat

# PowerShell
.\setup_complete_system.ps1
```

**Linux/macOS:**
```bash
chmod +x deploy_production.sh
./deploy_production.sh
```

### Manual Setup

1. **Start Docker services:**
```bash
docker-compose up -d mysql redis
```

2. **Run database migration:**
```bash
python migrate_database.py
```

3. **Seed database:**
```bash
python seed_data_standalone.py
```

4. **Start backend and admin:**
```bash
docker-compose up -d backend admin
```

5. **Setup Flutter app:**
```bash
cd flutter_app
flutter pub get
flutter run
```

## 🏗️ Production Deployment

### Prerequisites

- **Server Requirements:**
  - Ubuntu 20.04+ or CentOS 8+
  - 4GB RAM minimum (8GB recommended)
  - 50GB storage
  - Domain name with SSL certificate

- **Software Requirements:**
  - Docker & Docker Compose
  - Git
  - Nginx (optional, for reverse proxy)

### Production Setup

1. **Clone and configure:**
```bash
git clone <your-repo>
cd fertility_services_app
cp env.example .env
# Edit .env with your production values
```

2. **Configure environment variables:**
```bash
# Database
DB_HOST=your-db-host
DB_PORT=3306
DB_USER=your-db-user
DB_PASSWORD=your-secure-password
DB_NAME=fertility_services

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=False
SECRET_KEY=your-super-secret-key

# Payment Gateways
PAYSTACK_PUBLIC_KEY=pk_live_your_key
PAYSTACK_SECRET_KEY=sk_live_your_key
PAYSTACK_WEBHOOK_SECRET=whsec_your_webhook

# Domain Configuration
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

3. **Deploy with production profile:**
```bash
# Full production deployment with Nginx
docker-compose --profile production up -d --build

# Or use the deployment script
chmod +x deploy_production.sh
./deploy_production.sh
```

4. **Configure SSL certificates:**
```bash
# Copy your SSL certificates
cp your-cert.pem nginx/ssl/cert.pem
cp your-key.pem nginx/ssl/key.pem

# Update nginx configuration
nano nginx/conf.d/default.conf
# Change 'your-domain.com' to your actual domain
```

5. **Build Flutter app for production:**
```bash
# Build for production
./build_flutter_production.sh production yourdomain.com

# Or for staging
./build_flutter_production.sh staging staging.yourdomain.com
```

### Production URLs

After deployment, your services will be available at:

- **API Documentation:** `https://yourdomain.com/api/docs`
- **Admin Dashboard:** `https://yourdomain.com/admin/`
- **Health Check:** `https://yourdomain.com/health`

### Security Checklist

- [ ] Change default passwords
- [ ] Configure SSL certificates
- [ ] Set up firewall rules
- [ ] Enable rate limiting
- [ ] Configure backups
- [ ] Set up monitoring
- [ ] Update payment gateway keys
- [ ] Configure CORS properly
- [ ] Set up log rotation
- [ ] Enable security headers

### Monitoring and Maintenance

**Health Check:**
```bash
python check_services.py
```

**View Logs:**
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f admin
```

**Backup Database:**
```bash
docker-compose exec mysql mysqldump -u fertility_user -p fertility_services > backup.sql
```

**Update Services:**
```bash
docker-compose pull
docker-compose up -d --build
```

## 📱 Mobile App Development

### Environment Configuration

The Flutter app supports multiple environments:

**Development:**
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.106:8000/api/v1
```

**Staging:**
```bash
flutter run --dart-define=API_BASE_URL=https://staging-api.yourdomain.com/api/v1
```

**Production:**
```bash
flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

### Building for Production

**Android:**
```bash
# APK for testing
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

## 🔧 Configuration

### Environment Variables

Key environment variables for production:

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `3306` |
| `DB_USER` | Database user | `fertility_user` |
| `DB_PASSWORD` | Database password | `secure_password` |
| `SECRET_KEY` | JWT secret key | `your-secret-key` |
| `DEBUG` | Debug mode | `False` |
| `ALLOWED_ORIGINS` | CORS origins | `https://yourdomain.com` |

### Payment Gateway Configuration

Configure your payment gateways in the `.env` file:

```bash
# Paystack (Nigeria)
PAYSTACK_PUBLIC_KEY=pk_live_your_key
PAYSTACK_SECRET_KEY=sk_live_your_key
PAYSTACK_WEBHOOK_SECRET=whsec_your_webhook

# Stripe (International)
STRIPE_PUBLIC_KEY=pk_live_your_key
STRIPE_SECRET_KEY=sk_live_your_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook

# Flutterwave (Africa)
FLUTTERWAVE_PUBLIC_KEY=FLWPUBK_your_key
FLUTTERWAVE_SECRET_KEY=FLWSECK_your_key
FLUTTERWAVE_WEBHOOK_SECRET=whsec_your_webhook
```

## 🐳 Docker Configuration

### Development vs Production

**Development:**
```bash
docker-compose up -d
```

**Production:**
```bash
docker-compose --profile production up -d
```

### Service Profiles

- **Default:** Backend, Admin, MySQL, Redis
- **Production:** Adds Nginx reverse proxy
- **Hospital:** Adds hospital portal (optional)

### Resource Limits

Services are configured with resource limits:

```yaml
deploy:
  resources:
    limits:
      memory: 1G
    reservations:
      memory: 512M
```

## 📊 Services

| Service | Port | Description |
|---------|------|-------------|
| Backend API | 8000 | FastAPI backend |
| Admin Dashboard | 8501 | Streamlit admin interface |
| MySQL Database | 3307 | Database server |
| Redis Cache | 6379 | Cache server |
| Nginx (Production) | 80/443 | Reverse proxy |

## 🔐 Default Credentials

- **Admin:** `admin@fertilityservices.com` / `admin123`
- **Patient:** `patient1@example.com` / `password123`
- **Hospital:** `hospital1@example.com` / `password123`

**⚠️ Change these passwords in production!**

## 🚨 Troubleshooting

### Common Issues

**Database Connection Error:**
```bash
# Check if MySQL is running
docker-compose ps mysql

# Check logs
docker-compose logs mysql
```

**Backend Not Starting:**
```bash
# Check environment variables
docker-compose exec backend env | grep DB_

# Check logs
docker-compose logs backend
```

**Payment Gateway Issues:**
```bash
# Verify API keys in admin dashboard
# Check webhook configuration
# Test with payment gateway test mode first
```

### Health Check

Run the health check script to verify all services:

```bash
python check_services.py
```

### Logs

View logs for debugging:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f admin
docker-compose logs -f mysql
```

## 📚 API Documentation

- **Interactive Docs:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **OpenAPI JSON:** http://localhost:8000/openapi.json

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Documentation:** [API Docs](http://localhost:8000/docs)
- **Issues:** [GitHub Issues](https://github.com/your-repo/issues)
