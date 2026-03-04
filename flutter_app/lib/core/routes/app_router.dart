import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/hospital_model.dart';
import '../../core/models/service_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/appointments/screens/appointments_screen.dart';
import '../../features/appointments/screens/book_appointment_screen.dart';
import '../../features/appointments/screens/appointment_confirmation_screen.dart';
import '../../features/hospitals/screens/hospitals_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/security_screen.dart';
import '../../features/profile/screens/privacy_screen.dart';
import '../../features/profile/screens/notifications_screen.dart';
import '../../features/profile/screens/payments_screen.dart';
import '../../features/profile/screens/support_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/profile/screens/terms_screen.dart';
import '../../features/profile/screens/privacy_policy_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/home/screens/activity_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/messages/screens/user_search_screen.dart';
import '../../features/services/screens/service_details_screen.dart';
import '../../shared/widgets/main_navigation.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoading = authProvider.isLoading;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      // Don't redirect while loading
      if (isLoading) {
        return null;
      }

      if (!isLoggedIn && !isLoggingIn && !isRegistering) {
        return '/login';
      }
      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return '/';
      }
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Main App Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigation(child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          
          // Appointments
          GoRoute(
            path: '/appointments',
            name: 'appointments',
            builder: (context, state) => const AppointmentsScreen(),
            routes: [
              GoRoute(
                path: '/book',
                name: 'book-appointment',
                builder: (context, state) {
                  final hospitalId = state.uri.queryParameters['hospitalId'];
                  return BookAppointmentScreen(hospitalId: hospitalId);
                },
              ),
              GoRoute(
                path: '/confirmation',
                name: 'appointment-confirmation',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return AppointmentConfirmationScreen(
                    hospital: extra['hospital'] as Hospital,
                    service: extra['service'] as Service,
                    appointmentDate: extra['appointmentDate'] as DateTime,
                    timeSlot: extra['timeSlot'] as String,
                  );
                },
              ),
              GoRoute(
                path: '/:id',
                name: 'appointment-details',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AppointmentDetailsScreen(appointmentId: id);
                },
              ),
            ],
          ),
          
          // Hospitals
          GoRoute(
            path: '/hospitals',
            name: 'hospitals',
            builder: (context, state) => const HospitalsScreen(),
            routes: [
              GoRoute(
                path: '/:id',
                name: 'hospital-details',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return HospitalDetailsScreen(hospitalId: id);
                },
              ),
              GoRoute(
                path: '/map',
                name: 'hospitals-map',
                builder: (context, state) => const HospitalsMapScreen(),
              ),
            ],
          ),
          
          // Wallet
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          
          // Activity
          GoRoute(
            path: '/activity',
            name: 'activity',
            builder: (context, state) => const ActivityScreen(),
          ),
          
          // Services
          GoRoute(
            path: '/services',
            name: 'services',
            builder: (context, state) => const ServicesScreen(),
            routes: [
              GoRoute(
                path: '/:id',
                name: 'service-details',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ServiceDetailsScreen(serviceId: id);
                },
              ),
              GoRoute(
                path: '/sperm-donation',
                name: 'sperm-donation',
                builder: (context, state) => const SpermDonationScreen(),
              ),
              GoRoute(
                path: '/egg-donation',
                name: 'egg-donation',
                builder: (context, state) => const EggDonationScreen(),
              ),
              GoRoute(
                path: '/surrogacy',
                name: 'surrogacy',
                builder: (context, state) => const SurrogacyScreen(),
              ),
            ],
          ),
          
          // Messages
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const MessagesScreen(),
            routes: [
              GoRoute(
                path: '/search',
                name: 'user_search',
                builder: (context, state) {
                  final type = state.uri.queryParameters['type'];
                  return UserSearchScreen(initialUserType: type);
                },
              ),
              GoRoute(
                path: '/:id',
                name: 'chat',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ChatScreen(conversationId: id);
                },
              ),
              GoRoute(
                path: '/new',
                name: 'new-message',
                builder: (context, state) {
                  final type = state.uri.queryParameters['type'];
                  return NewMessageScreen(type: type);
                },
              ),
              GoRoute(
                path: '/archived',
                name: 'archived-messages',
                builder: (context, state) => const ArchivedMessagesScreen(),
              ),
              GoRoute(
                path: '/settings',
                name: 'message-settings',
                builder: (context, state) => const MessageSettingsScreen(),
              ),
            ],
          ),
          
          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: '/edit',
                name: 'edit-profile',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: '/security',
                name: 'profile-security',
                builder: (context, state) => const SecurityScreen(),
              ),
              GoRoute(
                path: '/privacy',
                name: 'profile-privacy',
                builder: (context, state) => const PrivacyScreen(),
              ),
              GoRoute(
                path: '/notifications',
                name: 'profile-notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: '/payments',
                name: 'profile-payments',
                builder: (context, state) => const PaymentsScreen(),
              ),
            ],
          ),
        ],
      ),
      
      // Standalone Routes (outside main navigation)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      
      GoRoute(
        path: '/payments',
        name: 'payments',
        builder: (context, state) => const PaymentsScreen(),
        routes: [
          GoRoute(
            path: '/:id',
            name: 'payment-details',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PaymentDetailsScreen(paymentId: id);
            },
          ),
        ],
      ),
      
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportScreen(),
      ),
      

      
      GoRoute(
        path: '/legal/terms',
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      
      GoRoute(
        path: '/legal/privacy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      

      
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
}

// Placeholder screens - these would be implemented as full screens
class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;
  
  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: Center(
        child: Text('Appointment Details Screen - ID: $appointmentId'),
      ),
    );
  }
}

class HospitalDetailsScreen extends StatelessWidget {
  final String hospitalId;
  
  const HospitalDetailsScreen({super.key, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hospital Details')),
      body: Center(
        child: Text('Hospital Details Screen - ID: $hospitalId'),
      ),
    );
  }
}

class HospitalsMapScreen extends StatelessWidget {
  const HospitalsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hospitals Map')),
      body: const Center(
        child: Text('Hospitals Map Screen - Coming Soon'),
      ),
    );
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: const Center(
        child: Text('Services Screen - Coming Soon'),
      ),
    );
  }
}

class SpermDonationScreen extends StatelessWidget {
  const SpermDonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sperm Donation')),
      body: const Center(
        child: Text('Sperm Donation Screen - Coming Soon'),
      ),
    );
  }
}

class EggDonationScreen extends StatelessWidget {
  const EggDonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Egg Donation')),
      body: const Center(
        child: Text('Egg Donation Screen - Coming Soon'),
      ),
    );
  }
}

class SurrogacyScreen extends StatelessWidget {
  const SurrogacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Surrogacy')),
      body: const Center(
        child: Text('Surrogacy Screen - Coming Soon'),
      ),
    );
  }
}

class NewMessageScreen extends StatelessWidget {
  final String? type;
  
  const NewMessageScreen({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Message')),
      body: Center(
        child: Text('New Message Screen - Type: ${type ?? 'General'}'),
      ),
    );
  }
}

class ArchivedMessagesScreen extends StatelessWidget {
  const ArchivedMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Messages')),
      body: const Center(
        child: Text('Archived Messages Screen - Coming Soon'),
      ),
    );
  }
}

class MessageSettingsScreen extends StatelessWidget {
  const MessageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Settings')),
      body: const Center(
        child: Text('Message Settings Screen - Coming Soon'),
      ),
    );
  }
}



// Remaining placeholder screens that haven't been implemented yet
class PaymentDetailsScreen extends StatelessWidget {
  final String paymentId;
  
  const PaymentDetailsScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: Center(
        child: Text('Payment Details Screen - ID: $paymentId'),
      ),
    );
  }
}



class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '404 - Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('The page you are looking for does not exist.'),
          ],
        ),
      ),
    );
  }
}
