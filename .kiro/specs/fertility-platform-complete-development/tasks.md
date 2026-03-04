# Implementation Plan: Fertility Services Platform Complete Development

## Overview

This implementation plan covers the complete development of the Fertility Services Platform, including 20 major feature areas across backend (Python FastAPI), mobile app (Flutter/Dart), and admin dashboard (Streamlit). The tasks are organized to build incrementally, with testing integrated throughout to ensure quality and reliability.

The implementation follows a layered approach:
1. Backend API services and database models
2. Mobile app UI and state management
3. Admin dashboard enhancements
4. Testing infrastructure
5. Security and compliance features
6. Integration and optimization

## Tasks

### Phase 1: Appointment Booking System

- [x] 1. Implement appointment booking backend services
  - [x] 1.1 Create appointment database models and migrations
    - Create Appointment model with fields: user_id, hospital_id, service_id, appointment_date, status, notes, price, reserved_until
    - Create database migration script
    - Add indexes on user_id, hospital_id, appointment_date, status, reserved_until
    - _Requirements: 1.1, 1.2, 1.5, 1.11_

  - [x] 1.2 Implement appointment service layer
    - Create AppointmentService class with methods: get_availability, reserve_slot, confirm_appointment, reschedule_appointment, cancel_appointment
    - Implement 10-minute reservation timeout logic using reserved_until field
    - Implement double-booking prevention using database locks
    - Add cache integration for availability slots (30s TTL)
    - _Requirements: 1.1, 1.2, 1.5, 1.6_

  - [ ]* 1.3 Write unit tests for appointment service
    - Test reservation timeout logic
    - Test double-booking prevention
    - Test cancellation refund calculations (100% >24h, 50% <24h)
    - _Requirements: 1.2, 1.5, 1.8, 1.9_

  - [x] 1.4 Implement appointment API endpoints
    - POST /api/v1/appointments/reserve - Reserve time slot
    - POST /api/v1/appointments/confirm - Confirm with payment
    - GET /api/v1/appointments - List user appointments
    - PUT /api/v1/appointments/{id}/reschedule - Reschedule appointment
    - DELETE /api/v1/appointments/{id} - Cancel appointment
    - GET /api/v1/hospitals/{id}/availability - Get available slots
    - _Requirements: 1.1, 1.2, 1.3, 1.7_


  - [ ]* 1.5 Write integration tests for appointment endpoints
    - Test complete booking flow: reserve → confirm → payment
    - Test rescheduling with availability checks
    - Test cancellation with refund processing
    - _Requirements: 1.2, 1.3, 1.4, 1.7, 1.8, 1.9_

  - [x] 1.6 Integrate appointment reminders with notification service
    - Implement scheduled task for 24-hour reminders
    - Implement scheduled task for 1-hour reminders
    - Queue reminder notifications using Celery
    - _Requirements: 1.10_

- [ ] 2. Implement appointment booking mobile UI
  - [x] 2.1 Create hospital availability screen
    - Build calendar widget for date selection
    - Display available time slots in grid layout
    - Implement slot selection with visual feedback
    - Show service details and pricing
    - _Requirements: 1.1_

  - [x] 2.2 Create appointment confirmation screen
    - Display selected appointment details
    - Integrate payment gateway selection
    - Show terms and conditions
    - Implement confirm button with loading state
    - _Requirements: 1.3, 1.4_

  - [x] 2.3 Create appointment management screen
    - Display list of user appointments with status badges
    - Implement filter by status (upcoming, completed, cancelled)
    - Add reschedule and cancel actions
    - Show appointment details in expandable cards
    - _Requirements: 1.7_

  - [x] 2.4 Implement appointment state management
    - Create AppointmentProvider with state for appointments list, loading, error
    - Implement methods: loadAppointments, bookAppointment, rescheduleAppointment, cancelAppointment
    - Add optimistic updates for better UX
    - Handle reservation timeout countdown
    - _Requirements: 1.2, 1.7_


- [x] 3. Checkpoint - Verify appointment booking flow
  - Ensure all tests pass, verify end-to-end booking flow works correctly, ask the user if questions arise.

### Phase 2: Service Catalog Management

- [x] 4. Implement service catalog backend
  - [x] 4.1 Create service database models and migrations
    - Create Service model with fields: hospital_id, name, description, price, duration_minutes, category, is_active, is_featured
    - Add validation for positive prices
    - Create indexes on hospital_id, category, is_featured, price
    - Add full-text search index on name and description
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 4.2 Implement service catalog service layer
    - Create ServiceCatalogService with CRUD methods
    - Implement soft delete (archive) for services
    - Prevent deletion of services with active appointments
    - Add view count and booking count tracking
    - Implement CSV import/export functionality
    - _Requirements: 2.1, 2.8, 2.9, 2.10, 2.11, 2.12_

  - [ ]* 4.3 Write unit tests for service catalog
    - Test price validation (positive numbers only)
    - Test soft delete and archive logic
    - Test prevention of deletion with active appointments
    - Test CSV parsing and round-trip property
    - _Requirements: 2.3, 2.8, 2.9, 2.13_

  - [x] 4.4 Implement service catalog API endpoints
    - GET /api/v1/services - List services with filters
    - POST /api/v1/services - Create service (hospital auth)
    - PUT /api/v1/services/{id} - Update service
    - DELETE /api/v1/services/{id} - Archive service
    - POST /api/v1/services/import - Bulk import from CSV
    - GET /api/v1/services/export - Export to CSV
    - _Requirements: 2.1, 2.5, 2.6, 2.10_

  - [ ]* 4.5 Write integration tests for service endpoints
    - Test service creation with validation
    - Test filtering by category, price range, featured status
    - Test CSV import with valid and invalid data
    - Test response time <500ms for search queries
    - _Requirements: 2.2, 2.3, 2.4, 2.5_


- [x] 5. Implement service catalog mobile UI
  - [x] 5.1 Create service listing screen
    - Display services in card layout with images
    - Show service name, price, duration, rating
    - Implement filter by category
    - Add sort by price, rating, popularity
    - _Requirements: 2.4, 2.5_

  - [x] 5.2 Create service detail screen
    - Display full service description
    - Show pricing and duration details
    - Display hospital information
    - Add "Book Now" button
    - Show related services
    - _Requirements: 2.2, 2.6_

  - [x] 5.3 Implement service state management
    - Create ServiceProvider with state for services list, filters, loading
    - Implement methods: loadServices, filterByCategory, sortServices
    - Cache service data for offline access
    - _Requirements: 2.5, 2.7_

- [x] 6. Implement service management in admin dashboard
  - [x] 6.1 Create service management UI
    - Display services table with search and filters
    - Add create/edit service form
    - Implement bulk import interface
    - Show service analytics (views, bookings, conversion rate)
    - _Requirements: 2.1, 2.6, 2.7, 2.10_

- [x] 7. Checkpoint - Verify service catalog functionality
  - Ensure all tests pass, verify service CRUD operations work correctly, ask the user if questions arise.

### Phase 3: Review and Rating System

- [x] 8. Implement review system backend
  - [x] 8.1 Create review database models and migrations
    - Create Review model with fields: user_id, hospital_id, appointment_id, rating, comment, is_flagged, hospital_response
    - Add unique constraint on (user_id, appointment_id)
    - Add indexes on hospital_id, rating, is_flagged
    - Add immutable_after timestamp field (48 hours)
    - _Requirements: 3.1, 3.2, 3.7, 3.11_


  - [x] 8.2 Implement review service layer
    - Create ReviewService with methods: submit_review, get_hospital_reviews, calculate_rating, flag_review, respond_to_review
    - Implement validation: rating 1-5, comment max 1000 chars
    - Implement profanity detection and auto-flagging
    - Calculate and update hospital average rating
    - Implement review immutability after 48 hours
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.11_

  - [ ]* 8.3 Write unit tests for review service
    - Test rating calculation accuracy
    - Test duplicate review prevention
    - Test character limit validation
    - Test immutability enforcement after 48 hours
    - _Requirements: 3.2, 3.3, 3.4, 3.7, 3.11_

  - [x] 8.4 Implement review API endpoints
    - POST /api/v1/reviews - Submit review
    - GET /api/v1/reviews - List reviews with filters
    - POST /api/v1/reviews/{id}/flag - Flag review
    - POST /api/v1/reviews/{id}/respond - Hospital response
    - PUT /api/v1/reviews/{id}/moderate - Admin moderation
    - _Requirements: 3.1, 3.6, 3.8, 3.9, 3.10_

  - [ ]* 8.5 Write integration tests for review endpoints
    - Test complete review submission flow
    - Test filtering by rating and date range
    - Test auto-hide after multiple reports
    - Test rating update within 5 seconds
    - _Requirements: 3.4, 3.8, 3.9, 3.10_

- [x] 9. Implement review system mobile UI
  - [x] 9.1 Create review submission screen
    - Build star rating input widget
    - Add text input for comment (1000 char limit)
    - Show character counter
    - Implement submit button with validation
    - _Requirements: 3.2, 3.3_

  - [x] 9.2 Create reviews listing screen
    - Display reviews in card layout
    - Show rating, comment, date, hospital response
    - Implement filter by rating
    - Add sort by date (newest first)
    - Show flag/report button
    - _Requirements: 3.8, 3.9_

  - [x] 9.3 Implement review state management
    - Create ReviewProvider with state for reviews list, filters
    - Implement methods: submitReview, loadReviews, flagReview
    - Handle loading and error states
    - _Requirements: 3.1, 3.8_


- [x] 10. Implement review management in admin dashboard
  - [x] 10.1 Create review moderation UI
    - Display flagged reviews table
    - Show review details with context
    - Add approve/hide/delete actions
    - Display moderation history
    - _Requirements: 3.5, 3.10_

- [x] 11. Checkpoint - Verify review system functionality
  - Ensure all tests pass, verify review submission and moderation work correctly, ask the user if questions arise.

### Phase 4: Notification System

- [x] 12. Implement notification backend infrastructure
  - [x] 12.1 Create notification database models and migrations
    - Create Notification model with fields: user_id, title, message, notification_type, channel, status, retry_count
    - Create NotificationPreferences model for user settings
    - Add indexes on user_id, status, scheduled_at
    - _Requirements: 4.1, 4.3, 4.7_

  - [x] 12.2 Implement notification service layer
    - Create NotificationService with methods: send_notification, send_bulk, schedule_notification, update_preferences
    - Implement multi-channel delivery (push, email, SMS)
    - Implement retry logic with exponential backoff (max 3 retries)
    - Implement notification templates
    - Add delivery tracking and analytics
    - _Requirements: 4.1, 4.2, 4.6, 4.8, 4.11_

  - [x] 12.3 Implement notification channel adapters
    - Create PushNotificationChannel using FCM
    - Create EmailChannel using SMTP/SendGrid
    - Create SMSChannel using Twilio/Africa's Talking
    - Implement channel interface with send method
    - _Requirements: 4.1, 4.2, 4.5_

  - [ ]* 12.4 Write unit tests for notification service
    - Test retry logic with exponential backoff
    - Test channel selection based on preferences
    - Test template rendering
    - Test opt-out preference enforcement
    - _Requirements: 4.3, 4.6, 4.10_


  - [x] 12.5 Implement notification API endpoints
    - GET /api/v1/notifications - List user notifications
    - PUT /api/v1/notifications/{id}/read - Mark as read
    - GET /api/v1/notifications/preferences - Get preferences
    - PUT /api/v1/notifications/preferences - Update preferences
    - POST /api/v1/notifications/test - Send test notification (admin)
    - _Requirements: 4.3, 4.7_

  - [ ]* 12.6 Write integration tests for notification endpoints
    - Test notification delivery within 30 seconds
    - Test preference updates
    - Test failed notification storage
    - _Requirements: 4.2, 4.3, 4.9_

  - [x] 12.7 Implement Celery tasks for scheduled notifications
    - Create task for appointment reminders (24h, 1h)
    - Create task for retry failed notifications
    - Create task for notification cleanup
    - Configure Celery beat schedule
    - _Requirements: 4.4, 4.6_

- [x] 13. Implement notification mobile UI
  - [x] 13.1 Create notifications screen
    - Display notifications list with unread badges
    - Group by date (Today, Yesterday, Earlier)
    - Implement mark as read on tap
    - Add clear all button
    - Show notification icons by type
    - _Requirements: 4.7_

  - [x] 13.2 Create notification preferences screen
    - Display toggle switches for each channel
    - Group preferences by notification type
    - Add save button with confirmation
    - _Requirements: 4.3_

  - [x] 13.3 Implement notification state management
    - Create NotificationProvider with state for notifications list, unread count
    - Implement methods: loadNotifications, markAsRead, updatePreferences
    - Handle real-time updates from FCM
    - _Requirements: 4.3, 4.7_

- [ ] 14. Checkpoint - Verify notification system functionality
  - Ensure all tests pass, verify multi-channel delivery works correctly, ask the user if questions arise.


### Phase 5: Enhanced Admin Dashboard

- [ ] 15. Implement enhanced admin dashboard UI
  - [ ] 15.1 Create dashboard overview page
    - Display KPI cards (total users, appointments, revenue, active hospitals)
    - Implement interactive charts using Plotly (user growth, revenue trends)
    - Add date range filter with preset options
    - Show real-time system health indicators
    - Implement auto-refresh every 30 seconds
    - _Requirements: 5.1, 5.2, 5.3, 5.9_

  - [ ] 15.2 Implement user management module
    - Create users table with search and filters
    - Add user detail view with drill-down
    - Implement user activation/deactivation
    - Show user activity timeline
    - _Requirements: 5.6_

  - [ ] 15.3 Implement hospital management module
    - Create hospitals table with verification status
    - Add hospital approval workflow
    - Show hospital performance metrics
    - Implement hospital detail view
    - _Requirements: 5.1, 5.6_

  - [ ] 15.4 Implement appointment management module
    - Create appointments table with status filters
    - Add appointment detail view
    - Show appointment analytics
    - Implement bulk actions
    - _Requirements: 5.1, 5.6_

  - [ ] 15.5 Implement payment management module
    - Create payments table with gateway filters
    - Show payment analytics and trends
    - Add refund processing interface
    - Display payment gateway health status
    - _Requirements: 5.1, 5.6_

  - [ ] 15.6 Implement analytics and reporting module
    - Create custom report builder
    - Add export to PDF and CSV functionality
    - Implement scheduled report delivery
    - Show cohort analysis visualizations
    - Add funnel analysis for booking conversion
    - _Requirements: 5.4, 5.6_


  - [ ] 15.7 Implement UI/UX enhancements
    - Add dark mode and light mode themes
    - Implement responsive design for tablet viewports
    - Add loading skeletons for better perceived performance
    - Implement toast notifications for actions
    - Add keyboard shortcuts for common actions
    - _Requirements: 5.7, 5.10_

  - [ ] 15.8 Implement caching for dashboard performance
    - Cache frequently accessed metrics (5 min TTL)
    - Implement Redis caching for dashboard queries
    - Add cache invalidation on data updates
    - Optimize page load time to <3 seconds
    - _Requirements: 5.8, 5.11_

  - [ ]* 15.9 Write integration tests for admin dashboard
    - Test dashboard metrics calculation
    - Test report generation and export
    - Test date range filtering
    - Test page load performance
    - _Requirements: 5.3, 5.4, 5.11_

- [ ] 16. Checkpoint - Verify admin dashboard enhancements
  - Ensure all tests pass, verify dashboard loads within 3 seconds, ask the user if questions arise.

### Phase 6: Additional Payment Gateway Integration

- [ ] 17. Implement payment gateway infrastructure
  - [ ] 17.1 Create payment gateway adapter interface
    - Define PaymentGatewayAdapter abstract class
    - Define methods: initialize_transaction, verify_transaction, process_refund, validate_webhook
    - Create PaymentGatewayFactory for gateway selection
    - _Requirements: 6.1, 6.2_

  - [ ] 17.2 Implement Paystack adapter
    - Create PaystackAdapter implementing PaymentGatewayAdapter
    - Implement transaction initialization
    - Implement webhook signature validation
    - Implement refund processing
    - _Requirements: 6.1, 6.3, 6.10_

  - [ ] 17.3 Implement Stripe adapter
    - Create StripeAdapter implementing PaymentGatewayAdapter
    - Implement payment intent creation
    - Implement webhook handling
    - Implement refund processing
    - _Requirements: 6.1, 6.3, 6.10_


  - [ ] 17.4 Implement Flutterwave adapter
    - Create FlutterwaveAdapter implementing PaymentGatewayAdapter
    - Implement transaction initialization
    - Implement webhook validation
    - Implement refund processing
    - _Requirements: 6.1, 6.3, 6.10_

  - [ ] 17.5 Implement M-Pesa adapter
    - Create MPesaAdapter implementing PaymentGatewayAdapter
    - Implement STK Push for payment initiation
    - Implement callback handling
    - Handle M-Pesa specific error codes
    - _Requirements: 6.1, 6.3_

  - [ ] 17.6 Implement payment service enhancements
    - Add gateway selection based on user location
    - Implement multi-currency support (NGN, USD, KES, GHS)
    - Add automatic currency conversion
    - Implement split payment distribution
    - Store payment method tokens securely
    - _Requirements: 6.2, 6.5, 6.6, 6.7, 6.11_

  - [ ]* 17.7 Write unit tests for payment gateways
    - Test each adapter's transaction flow
    - Test webhook signature validation
    - Test refund processing
    - Test currency conversion
    - _Requirements: 6.3, 6.4, 6.6, 6.9_

  - [ ] 17.8 Implement payment API enhancements
    - POST /api/v1/payments/initialize - Initialize payment with gateway selection
    - POST /api/v1/payments/webhook/{gateway} - Handle gateway webhooks
    - GET /api/v1/payments/{id}/verify - Verify payment status
    - POST /api/v1/payments/{id}/refund - Process refund
    - GET /api/v1/payments/methods - Get saved payment methods
    - POST /api/v1/payments/methods - Save payment method
    - _Requirements: 6.2, 6.3, 6.7, 6.9_

  - [ ]* 17.9 Write integration tests for payment endpoints
    - Test payment flow with each gateway
    - Test webhook processing
    - Test refund completion within 5 business days
    - Test PCI DSS compliance
    - _Requirements: 6.3, 6.4, 6.8, 6.9_


- [ ] 18. Implement payment UI in mobile app
  - [ ] 18.1 Create payment method selection screen
    - Display available payment gateways based on location
    - Show saved payment methods
    - Add new payment method option
    - Display currency and converted amount
    - _Requirements: 6.2, 6.5, 6.6, 6.7_

  - [ ] 18.2 Create payment processing screen
    - Integrate WebView for gateway checkout
    - Show payment progress indicator
    - Handle payment success/failure callbacks
    - Display clear error messages
    - _Requirements: 6.3, 6.4_

  - [ ] 18.3 Implement payment state management
    - Create PaymentProvider with state for payment methods, processing status
    - Implement methods: initializePayment, verifyPayment, savePaymentMethod
    - Handle payment callbacks and redirects
    - _Requirements: 6.2, 6.3, 6.7_

- [ ] 19. Checkpoint - Verify payment gateway integration
  - Ensure all tests pass, verify payments work with all gateways, ask the user if questions arise.

### Phase 7: Enhanced Search and Filtering

- [ ] 20. Implement advanced search backend
  - [ ] 20.1 Enhance search service layer
    - Implement full-text search using MySQL FULLTEXT indexes
    - Add relevance scoring algorithm
    - Implement autocomplete using trigram matching
    - Add geolocation-based search with distance calculation
    - Implement search result caching (10 min TTL)
    - Track popular search terms
    - _Requirements: 7.1, 7.2, 7.4, 7.8, 7.10, 7.11_

  - [ ] 20.2 Implement advanced filtering
    - Add filters: location, price range, rating, service type, availability
    - Implement multi-criteria filtering
    - Add sort options: relevance, distance, rating, price
    - Optimize filter queries with proper indexes
    - _Requirements: 7.3, 7.6_


  - [ ]* 20.3 Write unit tests for search service
    - Test relevance scoring algorithm
    - Test autocomplete with various inputs
    - Test geolocation distance calculations
    - Test search result caching
    - _Requirements: 7.1, 7.4, 7.8, 7.11_

  - [ ] 20.4 Implement search API endpoints
    - GET /api/v1/search - Main search with filters
    - GET /api/v1/search/autocomplete - Autocomplete suggestions
    - GET /api/v1/search/nearby - Geolocation search
    - GET /api/v1/search/popular - Popular search terms
    - _Requirements: 7.1, 7.4, 7.8, 7.10_

  - [ ]* 20.5 Write integration tests for search endpoints
    - Test search response time <500ms
    - Test autocomplete after 3 characters
    - Test filter combinations
    - Test sort options
    - _Requirements: 7.2, 7.4, 7.6_

- [ ] 21. Implement search UI in mobile app
  - [ ] 21.1 Create search screen with filters
    - Build search bar with autocomplete dropdown
    - Add filter chips for quick filtering
    - Implement advanced filter modal
    - Show search result count
    - Highlight search terms in results
    - _Requirements: 7.1, 7.3, 7.4, 7.7_

  - [ ] 21.2 Implement search results screen
    - Display results in list/grid layout
    - Show distance for nearby results
    - Add sort dropdown
    - Implement infinite scroll pagination
    - Show "no results" with suggestions
    - _Requirements: 7.5, 7.6, 7.9_

  - [ ] 21.3 Implement search state management
    - Create SearchProvider with state for query, filters, results, loading
    - Implement methods: search, autocomplete, applyFilters, sortResults
    - Debounce search input (300ms)
    - Cache search results locally
    - _Requirements: 7.1, 7.2, 7.11_

- [ ] 22. Checkpoint - Verify search functionality
  - Ensure all tests pass, verify search returns results within 500ms, ask the user if questions arise.


### Phase 8: Analytics and Reporting

- [ ] 23. Implement analytics engine backend
  - [ ] 23.1 Create analytics database models
    - Create analytics aggregation tables for performance
    - Add indexes for time-series queries
    - Create materialized views for common reports
    - _Requirements: 8.1, 8.2_

  - [ ] 23.2 Implement analytics service layer
    - Create AnalyticsEngine with methods: get_dashboard_metrics, generate_report, get_cohort_analysis, get_funnel_analysis
    - Implement KPI calculations (user acquisition, retention, revenue)
    - Implement cohort analysis for user behavior
    - Implement funnel analysis for booking conversion
    - Add data aggregation for privacy protection
    - _Requirements: 8.2, 8.4, 8.5, 8.6, 8.10_

  - [ ] 23.3 Implement report generation
    - Create report templates for common reports
    - Implement PDF generation using ReportLab
    - Implement CSV export
    - Implement JSON export with round-trip property
    - Add scheduled report delivery via email
    - _Requirements: 8.1, 8.3, 8.9, 8.11, 8.12, 8.13, 8.14_

  - [ ]* 23.4 Write unit tests for analytics engine
    - Test KPI calculation accuracy
    - Test cohort analysis logic
    - Test funnel analysis calculations
    - Test JSON round-trip property for reports
    - _Requirements: 8.2, 8.4, 8.5, 8.6, 8.14_

  - [ ] 23.5 Implement analytics API endpoints
    - GET /api/v1/admin/analytics/dashboard - Dashboard metrics
    - POST /api/v1/admin/analytics/reports - Generate custom report
    - GET /api/v1/admin/analytics/reports/{id} - Download report
    - GET /api/v1/admin/analytics/cohorts - Cohort analysis
    - GET /api/v1/admin/analytics/funnels - Funnel analysis
    - GET /api/v1/admin/analytics/payments - Payment analytics
    - _Requirements: 8.1, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8_

  - [ ]* 23.6 Write integration tests for analytics endpoints
    - Test report generation within 60 seconds
    - Test export formats (JSON, CSV, PDF)
    - Test scheduled report delivery
    - _Requirements: 8.3, 8.9, 8.11_


- [ ] 24. Integrate analytics into admin dashboard
  - [ ] 24.1 Enhance analytics visualizations
    - Add interactive charts for all KPIs
    - Implement drill-down from charts to details
    - Add cohort analysis visualization
    - Add funnel visualization with conversion rates
    - Show payment gateway performance comparison
    - _Requirements: 8.4, 8.5, 8.6, 8.7_

  - [ ] 24.2 Implement report management UI
    - Create report builder interface
    - Add report scheduling interface
    - Show report history and downloads
    - Implement report preview
    - _Requirements: 8.1, 8.3, 8.9_

- [ ] 25. Checkpoint - Verify analytics functionality
  - Ensure all tests pass, verify reports generate within 60 seconds, ask the user if questions arise.

### Phase 9: Testing Infrastructure

- [ ] 26. Set up unit testing infrastructure
  - [ ] 26.1 Configure pytest for backend testing
    - Create pytest.ini configuration
    - Set up test database fixtures
    - Configure coverage reporting (target 80%)
    - Add pytest plugins (pytest-asyncio, pytest-mock)
    - _Requirements: 9.1, 9.5_

  - [ ] 26.2 Create test utilities and fixtures
    - Create database fixtures for test data
    - Create mock factories for external services
    - Create authentication fixtures
    - Create helper functions for common test operations
    - _Requirements: 9.3_

  - [ ] 26.3 Write unit tests for authentication service
    - Test user registration with validation
    - Test login with correct/incorrect credentials
    - Test JWT token generation and validation
    - Test password hashing and verification
    - Test session management
    - _Requirements: 9.2, 9.6, 9.7, 9.8, 9.9_


  - [ ] 26.4 Write unit tests for core services
    - Test AppointmentService methods
    - Test ServiceCatalogService methods
    - Test ReviewService methods
    - Test NotificationService methods
    - Test PaymentService methods
    - Test SearchService methods
    - _Requirements: 9.2, 9.6, 9.7, 9.8_

  - [ ] 26.5 Write unit tests for data models
    - Test model validation logic
    - Test serialization/deserialization
    - Test model relationships
    - Test custom model methods
    - _Requirements: 9.10_

  - [ ] 26.6 Configure CI/CD pipeline for unit tests
    - Create GitHub Actions workflow
    - Run tests on every commit
    - Generate and upload coverage reports
    - Fail build if coverage <80%
    - _Requirements: 9.11_

- [ ] 27. Set up integration testing infrastructure
  - [ ] 27.1 Configure integration test environment
    - Create docker-compose for test services
    - Set up test database with migrations
    - Configure test Redis instance
    - Create test data seeding scripts
    - _Requirements: 10.2, 10.3_

  - [ ] 27.2 Write integration tests for API endpoints
    - Test all authentication endpoints
    - Test all hospital endpoints
    - Test all appointment endpoints
    - Test all payment endpoints
    - Test all search endpoints
    - Test all review endpoints
    - Test all notification endpoints
    - _Requirements: 10.1, 10.4, 10.6_

  - [ ] 27.3 Write integration tests for workflows
    - Test complete user registration and login flow
    - Test complete appointment booking flow
    - Test complete payment processing flow
    - Test complete review submission flow
    - _Requirements: 10.4_


  - [ ] 27.4 Write integration tests for database operations
    - Test transaction commit and rollback
    - Test database constraints
    - Test cascade deletes
    - Test concurrent access handling
    - _Requirements: 10.5_

  - [ ] 27.5 Write integration tests for external services
    - Test CORS configuration
    - Test file upload/download
    - Test webhook handling for payment gateways
    - Test email sending
    - _Requirements: 10.7, 10.8, 10.9_

  - [ ] 27.6 Configure CI/CD for integration tests
    - Add integration test stage to GitHub Actions
    - Run tests with test database
    - Generate integration test reports
    - Complete tests within 15 minutes
    - _Requirements: 10.10, 10.11_

- [ ] 28. Set up end-to-end testing infrastructure
  - [ ] 28.1 Configure E2E test environment
    - Set up Flutter integration test framework
    - Configure test devices/emulators
    - Set up test payment gateway credentials
    - Create E2E test data fixtures
    - _Requirements: 11.2, 11.5_

  - [ ] 28.2 Write E2E tests for critical user journeys
    - Test patient registration and onboarding
    - Test hospital search and filtering
    - Test appointment booking end-to-end
    - Test payment processing
    - Test review submission
    - _Requirements: 11.1, 11.5_

  - [ ] 28.3 Write E2E tests for mobile app features
    - Test cross-platform compatibility (Android/iOS)
    - Test notification delivery
    - Test offline functionality and sync
    - Test deep linking from notifications
    - _Requirements: 11.4, 11.6, 11.7, 11.8_

  - [ ] 28.4 Configure E2E test reporting
    - Capture screenshots on test failure
    - Generate video recordings of failed tests
    - Create detailed test execution logs
    - _Requirements: 11.3, 11.11_


  - [ ] 28.5 Configure nightly E2E test runs
    - Schedule E2E tests to run nightly
    - Run before production deployments
    - Complete critical path tests within 30 minutes
    - Send test results to team
    - _Requirements: 11.9, 11.10_

- [ ] 29. Checkpoint - Verify testing infrastructure
  - Ensure all test suites run successfully, verify coverage meets targets, ask the user if questions arise.

### Phase 10: Performance Optimization

- [ ] 30. Implement database optimizations
  - [ ] 30.1 Add database indexes
    - Create indexes on user_id, hospital_id, appointment_date
    - Create composite indexes for common query patterns
    - Create full-text indexes for search
    - Analyze and optimize slow queries
    - _Requirements: 12.2_

  - [ ] 30.2 Implement database connection pooling
    - Configure SQLAlchemy connection pool (min 10, max 50)
    - Implement connection health checks
    - Add connection timeout configuration
    - Monitor connection pool usage
    - _Requirements: 12.5_

  - [ ] 30.3 Optimize database queries
    - Implement lazy loading for relationships
    - Use select_related and prefetch_related
    - Optimize N+1 query problems
    - Add query result caching
    - _Requirements: 12.6, 12.8_

  - [ ]* 30.4 Write performance tests for database
    - Test query execution time
    - Test connection pool under load
    - Test concurrent query handling
    - _Requirements: 12.2, 12.5, 12.8_

- [ ] 31. Implement caching strategies
  - [ ] 31.1 Implement Redis caching layer
    - Cache hospital listings (5 min TTL)
    - Cache service catalogs (10 min TTL)
    - Cache availability slots (30 sec TTL)
    - Cache search results (10 min TTL)
    - _Requirements: 12.3_


  - [ ] 31.2 Implement cache invalidation
    - Invalidate related caches on data updates
    - Implement cache invalidation within 5 seconds
    - Add cache versioning for breaking changes
    - Monitor cache hit rates
    - _Requirements: 12.4_

  - [ ]* 31.3 Write tests for caching layer
    - Test cache hit/miss scenarios
    - Test cache invalidation
    - Test cache TTL expiration
    - _Requirements: 12.3, 12.4_

- [ ] 32. Implement API optimizations
  - [ ] 32.1 Implement response compression
    - Enable gzip compression for responses >1KB
    - Configure compression level
    - Add compression headers
    - _Requirements: 12.10_

  - [ ] 32.2 Implement pagination
    - Add pagination to all list endpoints
    - Set maximum page size to 50 items
    - Implement cursor-based pagination for large datasets
    - Add pagination metadata to responses
    - _Requirements: 12.9_

  - [ ] 32.3 Optimize API response times
    - Target 95% of requests <200ms
    - Implement request timing middleware
    - Log slow requests for analysis
    - Optimize serialization performance
    - _Requirements: 12.1_

  - [ ]* 32.4 Write performance tests for API
    - Test response time under normal load
    - Test pagination performance
    - Test compression effectiveness
    - _Requirements: 12.1, 12.9, 12.10_

- [ ] 33. Implement load testing
  - [ ] 33.1 Set up load testing infrastructure
    - Configure Locust or k6 for load testing
    - Create load test scenarios
    - Set up monitoring during load tests
    - _Requirements: 12.7, 12.11_


  - [ ] 33.2 Run load tests
    - Test with 1000 concurrent users
    - Test with 5000 concurrent users
    - Identify performance bottlenecks
    - Verify no performance degradation
    - _Requirements: 12.7, 12.11_

  - [ ] 33.3 Optimize based on load test results
    - Address identified bottlenecks
    - Tune database and cache configurations
    - Optimize slow endpoints
    - Re-run load tests to verify improvements
    - _Requirements: 12.7, 12.11_

- [ ] 34. Checkpoint - Verify performance optimizations
  - Ensure 95% of requests respond within 200ms, verify load tests pass, ask the user if questions arise.

### Phase 11: Rate Limiting

- [ ] 35. Implement rate limiting system
  - [ ] 35.1 Create rate limiter service
    - Implement RateLimiter class with sliding window algorithm
    - Store counters in Redis for fast access
    - Implement different limits per endpoint category
    - Add whitelist/blacklist functionality
    - _Requirements: 13.1, 13.2, 13.4, 13.5, 13.8_

  - [ ] 35.2 Implement rate limiting middleware
    - Create FastAPI middleware for rate limiting
    - Return HTTP 429 with retry-after header
    - Log rate limit violations
    - Exempt admin users from limits
    - _Requirements: 13.3, 13.8, 13.9_

  - [ ] 35.3 Implement configurable rate limits
    - Create rate limit configuration system
    - Allow admin to update limits without code changes
    - Implement different limits for auth/unauth users
    - Add endpoint-specific limits
    - _Requirements: 13.1, 13.2, 13.6, 13.7_

  - [ ]* 35.4 Write unit tests for rate limiter
    - Test sliding window algorithm accuracy
    - Test limit enforcement
    - Test whitelist/blacklist functionality
    - Test admin exemption
    - _Requirements: 13.1, 13.2, 13.4, 13.8_


  - [ ] 35.5 Implement rate limit monitoring
    - Create API endpoint for checking rate limit status
    - Implement anomaly detection for suspicious patterns
    - Auto-increase restrictions on suspicious activity
    - Add rate limit metrics to admin dashboard
    - _Requirements: 13.10, 13.11_

  - [ ]* 35.6 Write integration tests for rate limiting
    - Test rate limit enforcement across requests
    - Test HTTP 429 response
    - Test retry-after header
    - Test violation logging
    - _Requirements: 13.3, 13.9_

- [ ] 36. Checkpoint - Verify rate limiting functionality
  - Ensure rate limits are enforced correctly, verify logging works, ask the user if questions arise.

### Phase 12: Audit Logging

- [ ] 37. Implement audit logging system
  - [ ] 37.1 Create audit log database model
    - Create AuditLog model with fields: timestamp, user_id, action, resource_type, resource_id, ip_address, user_agent, changes
    - Add indexes on user_id, timestamp, action, resource_type
    - Configure 7-year retention policy
    - _Requirements: 14.3, 14.6_

  - [ ] 37.2 Implement audit logger service
    - Create AuditLogger class with methods: log_event, search_logs, export_logs, detect_anomalies
    - Log all authentication events
    - Log all data modifications (create, update, delete)
    - Log all admin actions
    - Log all payment transactions
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

  - [ ] 37.3 Implement audit logging middleware
    - Create middleware to automatically log API requests
    - Capture request/response details
    - Extract user context and IP address
    - Store before/after state for updates
    - _Requirements: 14.2, 14.3_


  - [ ] 37.4 Implement audit log protection
    - Prevent modification/deletion by non-admin users
    - Implement tamper-proof log storage
    - Add log integrity verification
    - _Requirements: 14.10_

  - [ ] 37.5 Implement audit log search and export
    - Create search interface with filters
    - Implement export to CSV/JSON for compliance
    - Add date range filtering
    - Add user/action/resource filtering
    - _Requirements: 14.8, 14.9_

  - [ ]* 37.6 Write unit tests for audit logger
    - Test event logging accuracy
    - Test search and filtering
    - Test export functionality
    - Test log protection
    - _Requirements: 14.2, 14.3, 14.8, 14.10_

  - [ ] 37.7 Implement audit log monitoring
    - Implement anomaly detection algorithms
    - Generate alerts for suspicious patterns
    - Add audit log metrics to admin dashboard
    - _Requirements: 14.11_

  - [ ] 37.8 Implement log rotation
    - Configure automatic log rotation
    - Archive old logs to cold storage
    - Implement retention policy enforcement
    - _Requirements: 14.7_

- [ ] 38. Integrate audit logging into admin dashboard
  - [ ] 38.1 Create audit log viewer UI
    - Display audit logs table with search
    - Add filters for user, action, resource, date
    - Implement export functionality
    - Show log details in modal
    - Display anomaly alerts
    - _Requirements: 14.8, 14.9, 14.11_

- [ ] 39. Checkpoint - Verify audit logging functionality
  - Ensure all events are logged correctly, verify search and export work, ask the user if questions arise.


### Phase 13: GDPR Compliance

- [ ] 40. Implement GDPR compliance features
  - [ ] 40.1 Create GDPR database models
    - Create GDPRConsent model with fields: user_id, purpose, consent_given, consent_version, withdrawn_at
    - Create DataExportRequest model
    - Create DataDeletionRequest model
    - Add indexes on user_id and purpose
    - _Requirements: 15.1, 15.8_

  - [ ] 40.2 Implement consent management
    - Create GDPRModule class with consent methods
    - Implement consent recording with version tracking
    - Implement consent withdrawal
    - Display privacy notices at data collection points
    - Maintain consent audit trail
    - _Requirements: 15.1, 15.6, 15.8, 15.11_

  - [ ] 40.3 Implement data export functionality
    - Create data export service
    - Generate complete user data package in JSON format
    - Include all user data across all tables
    - Implement JSON round-trip property
    - Complete export within 30 days
    - _Requirements: 15.2, 15.3, 15.10, 15.12, 15.13, 15.14_

  - [ ] 40.4 Implement data deletion functionality
    - Create data anonymization service
    - Anonymize personal data while retaining anonymized records
    - Retain data for legal/financial compliance
    - Complete deletion within 30 days
    - _Requirements: 15.4, 15.5_

  - [ ] 40.5 Implement data minimization
    - Review all data collection points
    - Collect only necessary information
    - Add data retention policies
    - Implement automatic data cleanup
    - _Requirements: 15.9_

  - [ ]* 40.6 Write unit tests for GDPR module
    - Test consent recording and withdrawal
    - Test data export completeness
    - Test data anonymization
    - Test JSON round-trip property
    - _Requirements: 15.1, 15.2, 15.4, 15.14_


  - [ ] 40.7 Implement GDPR API endpoints
    - POST /api/v1/gdpr/consent - Record consent
    - DELETE /api/v1/gdpr/consent/{purpose} - Withdraw consent
    - GET /api/v1/gdpr/consents - List user consents
    - POST /api/v1/gdpr/export - Request data export
    - GET /api/v1/gdpr/export/{id} - Download export
    - POST /api/v1/gdpr/delete-account - Request account deletion
    - _Requirements: 15.1, 15.2, 15.4, 15.7_

  - [ ]* 40.8 Write integration tests for GDPR endpoints
    - Test consent management flow
    - Test data export generation
    - Test account deletion process
    - _Requirements: 15.1, 15.2, 15.4_

- [ ] 41. Implement GDPR UI in mobile app
  - [ ] 41.1 Create privacy settings screen
    - Display consent purposes with toggle switches
    - Show privacy notice with version
    - Add data export request button
    - Add account deletion button
    - _Requirements: 15.1, 15.6, 15.7_

  - [ ] 41.2 Create consent dialogs
    - Show consent dialog at registration
    - Display clear purpose descriptions
    - Require explicit consent
    - Allow granular consent per purpose
    - _Requirements: 15.1, 15.6_

  - [ ] 41.3 Implement GDPR state management
    - Create GDPRProvider with consent state
    - Implement methods: recordConsent, withdrawConsent, requestExport, deleteAccount
    - _Requirements: 15.1, 15.2, 15.4, 15.7_

- [ ] 42. Integrate GDPR features into admin dashboard
  - [ ] 42.1 Create GDPR management UI
    - Display data export requests table
    - Display account deletion requests table
    - Show consent statistics
    - Add manual data export/deletion tools
    - _Requirements: 15.2, 15.4_

- [ ] 43. Checkpoint - Verify GDPR compliance
  - Ensure all GDPR features work correctly, verify data export completeness, ask the user if questions arise.


### Phase 14: Data Encryption

- [ ] 44. Implement encryption infrastructure
  - [ ] 44.1 Create encryption service
    - Create EncryptionService class with methods: encrypt_field, decrypt_field, hash_password, verify_password, rotate_keys
    - Implement AES-256 encryption for data at rest
    - Use separate keys for different data categories
    - Integrate with key management system
    - _Requirements: 16.1, 16.5, 16.7_

  - [ ] 44.2 Implement password hashing
    - Use bcrypt with minimum 12 rounds
    - Implement password verification
    - Add password strength validation
    - _Requirements: 16.10_

  - [ ] 44.3 Implement field-level encryption
    - Encrypt PII fields (email, phone, address)
    - Encrypt medical records and health information
    - Encrypt payment information per PCI DSS
    - Add transparent encryption/decryption in ORM
    - _Requirements: 16.3, 16.4, 16.9_

  - [ ] 44.4 Implement file encryption
    - Encrypt uploaded files (images, documents)
    - Store encrypted files with metadata
    - Decrypt on download
    - _Requirements: 16.8_

  - [ ]* 44.5 Write unit tests for encryption service
    - Test encryption/decryption round-trip
    - Test password hashing and verification
    - Test key rotation
    - Test different data categories
    - _Requirements: 16.1, 16.5, 16.6, 16.10_

- [ ] 45. Implement TLS configuration
  - [ ] 45.1 Configure TLS 1.3
    - Configure Nginx with TLS 1.3
    - Implement perfect forward secrecy
    - Configure strong cipher suites
    - Add HSTS headers
    - _Requirements: 16.2, 16.11_

  - [ ] 45.2 Configure certificate management
    - Set up Let's Encrypt for SSL certificates
    - Implement automatic certificate renewal
    - Configure certificate monitoring
    - _Requirements: 16.2_


- [ ] 46. Implement key rotation
  - [ ] 46.1 Create key rotation service
    - Implement automatic key rotation every 90 days
    - Re-encrypt data with new keys
    - Maintain key version history
    - Schedule rotation tasks
    - _Requirements: 16.6_

  - [ ] 46.2 Implement key management
    - Store keys in secure key management system
    - Implement key access controls
    - Add key usage auditing
    - _Requirements: 16.7_

  - [ ]* 46.3 Write tests for key rotation
    - Test key rotation process
    - Test data re-encryption
    - Test key version management
    - _Requirements: 16.6_

- [ ] 47. Checkpoint - Verify encryption implementation
  - Ensure all sensitive data is encrypted, verify TLS configuration, ask the user if questions arise.

### Phase 15: Mobile App UI Screens

- [ ] 48. Implement authentication screens
  - [ ] 48.1 Create onboarding screens
    - Build welcome screen with app introduction
    - Create feature showcase carousel
    - Add skip and get started buttons
    - Implement smooth page transitions
    - _Requirements: 17.1, 17.11_

  - [ ] 48.2 Create registration screen
    - Build registration form with validation
    - Add user type selection (patient, donor, surrogate)
    - Implement password strength indicator
    - Add terms and privacy policy links
    - Show GDPR consent checkboxes
    - _Requirements: 17.1, 17.2_

  - [ ] 48.3 Create login screen
    - Build login form with email and password
    - Add "Remember me" checkbox
    - Implement "Forgot password" link
    - Add social login options
    - Show loading indicator during authentication
    - _Requirements: 17.1, 17.6_

  - [ ] 48.4 Create password reset screens
    - Build email input screen
    - Create verification code screen
    - Build new password screen
    - Add success confirmation
    - _Requirements: 17.1, 17.7_


- [ ] 49. Implement main navigation screens
  - [ ] 49.1 Create home screen
    - Build featured hospitals carousel
    - Display service categories grid
    - Show recent appointments
    - Add quick action buttons
    - Implement pull-to-refresh
    - _Requirements: 17.1, 17.9_

  - [ ] 49.2 Create bottom navigation
    - Implement bottom nav bar with icons
    - Add Home, Search, Appointments, Messages, Profile tabs
    - Highlight active tab
    - Implement smooth tab transitions
    - _Requirements: 17.3_

  - [ ] 49.3 Create search screen
    - Build search bar with autocomplete
    - Display recent searches
    - Show popular searches
    - Add filter button
    - _Requirements: 17.1_

  - [ ] 49.4 Create hospital listing screen
    - Display hospitals in card layout
    - Show hospital image, name, rating, distance
    - Implement infinite scroll
    - Add sort and filter options
    - _Requirements: 17.1, 17.9_

  - [ ] 49.5 Create hospital detail screen
    - Display hospital header with images
    - Show hospital information and services
    - Display reviews section
    - Add "Book Appointment" button
    - Show location map
    - _Requirements: 17.1_

- [ ] 50. Implement appointment screens
  - [ ] 50.1 Create appointment booking flow
    - Build service selection screen
    - Create date and time picker screen
    - Build appointment confirmation screen
    - Implement payment screen
    - Show booking success screen
    - _Requirements: 17.1, 17.6_

  - [ ] 50.2 Create appointments list screen
    - Display appointments with status badges
    - Group by upcoming, past, cancelled
    - Add filter and sort options
    - Implement swipe actions (reschedule, cancel)
    - _Requirements: 17.1_


  - [ ] 50.3 Create appointment detail screen
    - Display appointment information
    - Show hospital and service details
    - Add reschedule and cancel buttons
    - Display QR code for check-in
    - Show directions to hospital
    - _Requirements: 17.1_

- [ ] 51. Implement messaging screens
  - [ ] 51.1 Create messages list screen
    - Display conversations list
    - Show last message preview
    - Display unread badges
    - Implement search conversations
    - _Requirements: 17.1_

  - [ ] 51.2 Create chat screen
    - Build message thread UI
    - Implement message input with send button
    - Display message timestamps
    - Show read receipts
    - Add image attachment option
    - _Requirements: 17.1_

- [ ] 52. Implement profile and settings screens
  - [ ] 52.1 Create profile screen
    - Display user avatar and name
    - Show profile completion percentage
    - Add edit profile button
    - Display account statistics
    - _Requirements: 17.1_

  - [ ] 52.2 Create edit profile screen
    - Build profile form with validation
    - Add image picker for avatar
    - Implement save button
    - Show loading state during save
    - _Requirements: 17.1, 17.6_

  - [ ] 52.3 Create settings screen
    - Display settings grouped by category
    - Add notification preferences
    - Add privacy settings
    - Add language selection
    - Add theme toggle (dark/light)
    - Add logout button
    - _Requirements: 17.1_

  - [ ] 52.4 Create payment methods screen
    - Display saved payment methods
    - Add new payment method button
    - Implement delete payment method
    - Show default payment method
    - _Requirements: 17.1_


- [ ] 53. Implement accessibility and responsive design
  - [ ] 53.1 Implement accessibility features
    - Add semantic labels for screen readers
    - Implement adjustable text sizes
    - Add sufficient color contrast
    - Support keyboard navigation
    - Add focus indicators
    - _Requirements: 17.5_

  - [ ] 53.2 Implement responsive layouts
    - Support portrait and landscape orientations
    - Implement responsive breakpoints
    - Test on various screen sizes
    - Optimize for tablets
    - _Requirements: 17.4, 17.7_

  - [ ] 53.3 Implement error handling UI
    - Create error screens with retry options
    - Add inline validation errors
    - Show network error messages
    - Implement graceful degradation
    - _Requirements: 17.7_

- [ ] 54. Implement deep linking
  - [ ] 54.1 Configure deep linking
    - Set up URL schemes for iOS and Android
    - Configure app links and universal links
    - Implement deep link routing
    - Handle notification deep links
    - _Requirements: 17.8_

- [ ] 55. Implement image caching
  - [ ] 55.1 Configure image caching
    - Implement cached_network_image package
    - Configure cache size and duration
    - Add placeholder and error images
    - Implement offline image viewing
    - _Requirements: 17.10_

- [ ] 56. Checkpoint - Verify mobile app UI completion
  - Ensure all screens are implemented, verify navigation works correctly, ask the user if questions arise.


### Phase 16: State Management Implementation

- [ ] 57. Implement authentication state management
  - [ ] 57.1 Create AuthProvider
    - Implement state: currentUser, authStatus, loading, error
    - Implement methods: login, register, logout, refreshToken, resetPassword
    - Persist authentication state across app restarts
    - Handle token expiration and refresh
    - _Requirements: 18.1, 18.2, 18.4_

  - [ ] 57.2 Implement authentication guards
    - Create route guards for protected screens
    - Redirect to login if unauthenticated
    - Handle deep links with authentication
    - _Requirements: 18.2_

- [ ] 58. Implement data providers
  - [ ] 58.1 Create HospitalProvider
    - Implement state: hospitals, filters, loading, error
    - Implement methods: loadHospitals, searchHospitals, filterHospitals, getHospitalDetails
    - Implement optimistic updates
    - _Requirements: 18.1, 18.3, 18.5_

  - [ ] 58.2 Create AppointmentProvider (if not already created)
    - Implement state: appointments, loading, error
    - Implement methods: loadAppointments, bookAppointment, rescheduleAppointment, cancelAppointment
    - Handle loading, success, and error states
    - _Requirements: 18.1, 18.3, 18.6_

  - [ ] 58.3 Create ReviewProvider (if not already created)
    - Implement state: reviews, loading, error
    - Implement methods: loadReviews, submitReview, flagReview
    - Handle optimistic updates for review submission
    - _Requirements: 18.1, 18.3, 18.5_

  - [ ] 58.4 Create NotificationProvider (if not already created)
    - Implement state: notifications, unreadCount, loading
    - Implement methods: loadNotifications, markAsRead, updatePreferences
    - Handle real-time notification updates
    - _Requirements: 18.1, 18.3_


- [ ] 59. Implement global and local state separation
  - [ ] 59.1 Organize state architecture
    - Separate global state (user session, auth) from local state (screen-specific)
    - Implement provider hierarchy
    - Use MultiProvider for app-wide providers
    - Implement scoped providers for screen-specific state
    - _Requirements: 18.9_

  - [ ] 59.2 Implement state restoration
    - Save state on app backgrounding
    - Restore state on app foregrounding
    - Handle app termination and restart
    - _Requirements: 18.7_

- [ ] 60. Implement state debugging and testing
  - [ ] 60.1 Configure state debugging
    - Enable Provider DevTools in development
    - Implement state logging
    - Add time-travel debugging support
    - _Requirements: 18.10_

  - [ ] 60.2 Implement state serialization
    - Serialize state for testing
    - Create state factories for tests
    - Implement state mocking
    - _Requirements: 18.11_

  - [ ]* 60.3 Write tests for state management
    - Test provider state updates
    - Test optimistic updates
    - Test error handling
    - Test state restoration
    - _Requirements: 18.3, 18.5, 18.6, 18.7_

- [ ] 61. Implement resource disposal
  - [ ] 61.1 Implement proper cleanup
    - Dispose controllers and streams
    - Cancel pending requests on dispose
    - Remove listeners properly
    - Prevent memory leaks
    - _Requirements: 18.8_

- [ ] 62. Checkpoint - Verify state management implementation
  - Ensure state updates trigger UI rebuilds, verify no memory leaks, ask the user if questions arise.


### Phase 17: Offline Support

- [ ] 63. Implement local database
  - [ ] 63.1 Set up Hive database
    - Configure Hive for local storage
    - Create Hive adapters for data models
    - Initialize Hive boxes for different data types
    - _Requirements: 19.1_

  - [ ] 63.2 Create offline storage service
    - Create OfflineStorageService with methods: saveData, getData, deleteData, clearCache
    - Implement data serialization for Hive
    - Add cache size management
    - _Requirements: 19.1, 19.10_

- [ ] 64. Implement data caching
  - [ ] 64.1 Cache user data
    - Cache user profile locally
    - Cache appointments list
    - Cache messages and conversations
    - Update cache on data changes
    - _Requirements: 19.2_

  - [ ] 64.2 Cache hospital and service data
    - Cache hospital listings
    - Cache service details
    - Cache search results
    - Implement cache expiration (30 days)
    - _Requirements: 19.7, 19.10_

- [ ] 65. Implement offline detection
  - [ ] 65.1 Create connectivity service
    - Monitor network connectivity status
    - Detect online/offline transitions
    - Provide connectivity stream for reactive updates
    - _Requirements: 19.3_

  - [ ] 65.2 Implement offline indicator UI
    - Display offline banner when disconnected
    - Show cached data age indicator
    - Add "You're offline" message on actions
    - _Requirements: 19.3, 19.9_


- [ ] 66. Implement offline action queue
  - [ ] 66.1 Create action queue service
    - Queue user actions performed offline
    - Store actions with timestamps
    - Implement action serialization
    - _Requirements: 19.4_

  - [ ] 66.2 Implement sync service
    - Detect when connection is restored
    - Sync queued actions automatically within 30 seconds
    - Handle sync conflicts using last-write-wins
    - Show sync progress to user
    - _Requirements: 19.5, 19.6_

  - [ ] 66.3 Implement manual sync
    - Add manual sync button in settings
    - Show last sync timestamp
    - Display sync status (syncing, synced, failed)
    - _Requirements: 19.11_

- [ ] 67. Implement offline restrictions
  - [ ] 67.1 Disable real-time actions offline
    - Prevent appointment booking when offline
    - Prevent payment processing when offline
    - Show appropriate messages for disabled actions
    - Allow viewing cached data
    - _Requirements: 19.8_

  - [ ]* 67.2 Write tests for offline functionality
    - Test data caching
    - Test offline detection
    - Test action queuing
    - Test sync on reconnection
    - Test conflict resolution
    - _Requirements: 19.2, 19.3, 19.4, 19.5, 19.6_

- [ ] 68. Checkpoint - Verify offline support
  - Ensure app works offline, verify sync works on reconnection, ask the user if questions arise.

### Phase 18: Push Notifications Integration

- [ ] 69. Implement FCM integration
  - [ ] 69.1 Configure Firebase project
    - Set up Firebase project for iOS and Android
    - Download and add configuration files
    - Configure Firebase SDK in Flutter
    - _Requirements: 20.1_


  - [ ] 69.2 Request notification permissions
    - Request permissions on first launch
    - Handle permission granted/denied states
    - Show rationale for notification permissions
    - _Requirements: 20.2_

  - [ ] 69.3 Implement FCM token management
    - Register device token with backend API
    - Handle token refresh automatically
    - Update token on backend when changed
    - _Requirements: 20.7, 20.8_

- [ ] 70. Implement notification handling
  - [ ] 70.1 Handle foreground notifications
    - Display in-app notification when app is open
    - Show notification banner or dialog
    - Play notification sound
    - _Requirements: 20.3, 20.11_

  - [ ] 70.2 Handle background notifications
    - Display system notification when app is backgrounded
    - Update notification badge count
    - Store notification in local database
    - _Requirements: 20.3, 20.9, 20.11_

  - [ ] 70.3 Handle terminated state notifications
    - Display system notification when app is closed
    - Store notification for later retrieval
    - _Requirements: 20.11_

  - [ ] 70.4 Implement notification tap handling
    - Navigate to relevant screen on notification tap
    - Parse notification data payload
    - Handle different notification types
    - _Requirements: 20.4_

- [ ] 71. Implement notification categories
  - [ ] 71.1 Configure notification channels
    - Create channels for appointments, messages, promotions
    - Set channel importance levels
    - Configure channel sounds and vibration
    - _Requirements: 20.5_

  - [ ] 71.2 Implement notification preferences
    - Allow users to enable/disable per category
    - Save preferences locally and sync with backend
    - Apply preferences to notification display
    - _Requirements: 20.6_


- [ ] 72. Implement rich notifications
  - [ ] 72.1 Configure rich notification support
    - Support notifications with images
    - Implement action buttons on notifications
    - Handle notification actions
    - _Requirements: 20.10_

  - [ ] 72.2 Implement notification badges
    - Update app icon badge with unread count
    - Clear badge when notifications are read
    - Sync badge count across devices
    - _Requirements: 20.9_

  - [ ]* 72.3 Write tests for push notifications
    - Test token registration
    - Test notification handling in different states
    - Test notification navigation
    - Test notification preferences
    - _Requirements: 20.3, 20.4, 20.6, 20.7, 20.11_

- [ ] 73. Checkpoint - Verify push notifications
  - Ensure notifications are received in all app states, verify navigation works, ask the user if questions arise.

### Phase 19: Integration and Final Testing

- [ ] 74. Integrate all components
  - [ ] 74.1 Wire backend services together
    - Connect appointment service with payment service
    - Connect notification service with appointment reminders
    - Connect review service with hospital rating updates
    - Connect audit logger with all services
    - _Requirements: All backend requirements_

  - [ ] 74.2 Wire mobile app components together
    - Connect all screens with navigation
    - Connect all providers with API services
    - Integrate offline support across all features
    - Connect push notifications with app navigation
    - _Requirements: All mobile app requirements_

  - [ ] 74.3 Wire admin dashboard components
    - Connect all dashboard modules
    - Integrate analytics across all features
    - Connect audit log viewer
    - Connect GDPR management tools
    - _Requirements: All admin dashboard requirements_


- [ ] 75. Run comprehensive testing
  - [ ] 75.1 Run all unit tests
    - Execute complete unit test suite
    - Verify 80% code coverage achieved
    - Fix any failing tests
    - _Requirements: 9.1, 9.5_

  - [ ] 75.2 Run all integration tests
    - Execute complete integration test suite
    - Verify all API endpoints work correctly
    - Verify database transactions work correctly
    - Fix any failing tests
    - _Requirements: 10.1, 10.4, 10.5_

  - [ ] 75.3 Run all E2E tests
    - Execute complete E2E test suite
    - Test on Android and iOS devices
    - Verify critical user journeys work end-to-end
    - Fix any failing tests
    - _Requirements: 11.1, 11.4_

  - [ ] 75.4 Run performance tests
    - Execute load tests with 1000 and 5000 concurrent users
    - Verify 95% of requests respond within 200ms
    - Verify no performance degradation under load
    - Optimize any bottlenecks found
    - _Requirements: 12.1, 12.7, 12.11_

  - [ ] 75.5 Run security tests
    - Verify rate limiting works correctly
    - Verify encryption is applied to sensitive data
    - Verify authentication and authorization work correctly
    - Test for common vulnerabilities (SQL injection, XSS)
    - _Requirements: 13.1, 13.2, 16.1, 16.2_

- [ ] 76. Final verification and documentation
  - [ ] 76.1 Verify all requirements are met
    - Review all 20 feature areas
    - Verify all acceptance criteria are satisfied
    - Document any known limitations
    - _Requirements: All requirements_

  - [ ] 76.2 Update documentation
    - Update API documentation
    - Update deployment documentation
    - Update user guides
    - Document configuration options
    - _Requirements: All requirements_


- [ ] 77. Final checkpoint - Complete platform verification
  - Ensure all tests pass, verify all features work correctly, confirm platform is ready for deployment.

## Notes

This implementation plan covers all 20 major feature areas for the Fertility Services Platform:

1. Appointment Booking System (Tasks 1-3)
2. Service Catalog Management (Tasks 4-7)
3. Review and Rating System (Tasks 8-11)
4. Notification System (Tasks 12-14)
5. Enhanced Admin Dashboard UI (Tasks 15-16)
6. Additional Payment Gateway Options (Tasks 17-19)
7. Enhanced Search and Filtering (Tasks 20-22)
8. Analytics and Reporting (Tasks 23-25)
9. Unit Testing Infrastructure (Tasks 26)
10. Integration Testing Infrastructure (Tasks 27)
11. End-to-End Testing Infrastructure (Tasks 28)
12. Performance Optimization (Tasks 30-34)
13. Rate Limiting (Tasks 35-36)
14. Audit Logging (Tasks 37-39)
15. GDPR Compliance Features (Tasks 40-43)
16. Data Encryption (Tasks 44-47)
17. Complete Mobile App UI Screens (Tasks 48-56)
18. State Management Implementation (Tasks 57-62)
19. Offline Support (Tasks 63-68)
20. Push Notifications Integration (Tasks 69-73)

The tasks are organized to build incrementally with regular checkpoints. Testing tasks are marked with `*` as optional sub-tasks that can be skipped for faster MVP delivery, though they are highly recommended for production quality.

Each task references specific requirements for traceability, ensuring all acceptance criteria are covered. The implementation follows a layered approach starting with backend services, then mobile app features, followed by testing, security, and optimization.

The plan includes 77 top-level tasks with numerous sub-tasks, providing a comprehensive roadmap for completing the entire platform development.
