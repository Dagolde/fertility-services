# Complete Fertility Services App Setup Guide

## 🚀 Quick Start

### Prerequisites
- Docker Desktop (for full backend integration)
- Flutter SDK
- Android Studio/VS Code
- Git

### Option 1: Full Docker Setup (Recommended)

1. **Start Docker Desktop**
   ```bash
   # Make sure Docker Desktop is running
   ```

2. **Run Complete Setup**
   ```bash
   # Windows
   setup_complete_system.bat
   
   # Or manually:
   docker-compose up -d --build
   ```

3. **Access Services**
   - Backend API: http://localhost:8000
   - Admin Dashboard: http://localhost:8501
   - API Documentation: http://localhost:8000/docs

### Option 2: Local Development Setup

If Docker is not available, you can run services locally:

1. **Setup Python Backend**
   ```bash
   cd python_backend
   pip install -r requirements.txt
   python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

2. **Setup Admin Dashboard**
   ```bash
   cd admin_dashboard
   pip install -r requirements.txt
   streamlit run main.py --server.port 8501
   ```

3. **Setup Database (SQLite for local development)**
   - The app will automatically create a local SQLite database
   - Run `python seed_data.py` to populate with sample data

## 📱 Flutter App Setup

### 1. Fix Navigation Issues
The home navigation issue has been fixed by updating the route from '/home' to '/'.

### 2. Backend Integration
The app is configured to connect to:
- **Docker**: `http://10.0.2.2:8000/api/v1` (Android emulator)
- **Local**: Update `app_config.dart` to use `http://localhost:8000/api/v1`

### 3. Run Flutter App
```bash
cd flutter_app
flutter pub get
flutter run
```

## 🔧 Configuration

### Backend Configuration
- **Database**: MySQL (Docker) or SQLite (Local)
- **API Base URL**: Configured in `flutter_app/lib/core/config/app_config.dart`
- **Authentication**: JWT tokens with refresh mechanism

### Admin Panel Features
- User Management
- Hospital Management
- Appointment Tracking
- Message Monitoring
- Analytics Dashboard

## 🧪 Testing

### Test Accounts
After running the seed script, you can use these test accounts:

**Patients:**
- Email: `patient1@example.com` / Password: `password123`
- Email: `patient2@example.com` / Password: `password123`

**Hospitals:**
- Email: `hospital1@example.com` / Password: `password123`
- Email: `hospital2@example.com` / Password: `password123`

**Admin:**
- Email: `admin@fertilityservices.com` / Password: `admin123`

## 🐛 Troubleshooting

### Common Issues

1. **404 on Home Navigation**
   - ✅ Fixed: Updated navigation route from '/home' to '/'

2. **Docker Not Starting**
   - Ensure Docker Desktop is running
   - Check Windows Subsystem for Linux (WSL2) is enabled
   - Try: `docker-compose down` then `docker-compose up -d --build`

3. **Flutter Compilation Errors**
   - ✅ Fixed: Updated CustomTextField usage to SimpleTextField
   - Run: `flutter clean && flutter pub get`

4. **API Connection Issues**
   - Check if backend is running on correct port
   - Verify API URL in `app_config.dart`
   - For Android emulator, use `10.0.2.2` instead of `localhost`

5. **Database Connection Issues**
   - Ensure MySQL container is running
   - Check database credentials in `docker-compose.yml`
   - Wait for database initialization (30-60 seconds)

## 📊 Features Implemented

### Flutter App
- ✅ Authentication (Login/Register)
- ✅ Home Dashboard
- ✅ Hospital Listings
- ✅ Appointment Booking
- ✅ Messaging System
- ✅ Profile Management
- ✅ Navigation Fixed

### Backend API
- ✅ User Authentication & Authorization
- ✅ Hospital Management
- ✅ Appointment System
- ✅ Messaging System
- ✅ File Upload Support
- ✅ Admin APIs

### Admin Dashboard
- ✅ User Management
- ✅ Hospital Verification
- ✅ Appointment Monitoring
- ✅ System Analytics
- ✅ Content Management

## 🔄 Data Flow

1. **User Registration/Login**
   - Flutter App → Backend API → Database
   - JWT tokens stored securely
   - User data synced across devices

2. **Hospital Data**
   - Admin Panel → Backend API → Database → Flutter App
   - Real-time updates via API calls

3. **Appointments**
   - Flutter App → Backend API → Database
   - Admin can monitor via dashboard

4. **Messages**
   - Flutter App ↔ Backend API ↔ Database
   - Real-time messaging support

## 🚀 Deployment

### Production Setup
1. Update environment variables
2. Configure SSL certificates
3. Set up production database
4. Deploy using Docker Compose
5. Configure reverse proxy (Nginx)

### Environment Variables
```env
DATABASE_URL=mysql://user:password@host:port/database
SECRET_KEY=your-secret-key
DEBUG=False
REDIS_URL=redis://redis:6379
```

## 📞 Support

If you encounter any issues:
1. Check this troubleshooting guide
2. Review Docker logs: `docker-compose logs`
3. Check Flutter logs: `flutter logs`
4. Verify API endpoints: http://localhost:8000/docs
