import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service_simple.dart';

// Features
import 'features/auth/providers/auth_provider.dart';

// Shared
import 'shared/widgets/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start the app immediately, handle initialization inside the app
  runApp(const FertilityServicesApp());
}

class FertilityServicesApp extends StatefulWidget {
  const FertilityServicesApp({super.key});

  @override
  State<FertilityServicesApp> createState() => _FertilityServicesAppState();
}

class _FertilityServicesAppState extends State<FertilityServicesApp> {
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize services (without Firebase)
      await StorageService.init();
      ApiService.init(); // Initialize API service
      
      print('✅ Services initialized successfully');
      print('✅ API Base URL: ${AppConfig.baseUrl}');
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Initialization error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isInitialized = true; // Still set to true to show the app
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (!_isInitialized) {
      return MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const LoadingScreen(),
      );
    }

    // Show error screen if initialization failed
    if (_hasError) {
      return MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Initialization Error'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize the app',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isInitialized = false;
                      _hasError = false;
                      _errorMessage = '';
                    });
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal app flow
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Show loading screen while auth is initializing
          if (authProvider.isLoading) {
            return MaterialApp(
              title: AppConfig.appName,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system,
              debugShowCheckedModeBanner: false,
              home: const LoadingScreen(),
            );
          }
          
          return MaterialApp.router(
            title: AppConfig.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
