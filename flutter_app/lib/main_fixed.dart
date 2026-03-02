import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';

// Features
import 'features/home/screens/home_screen.dart';

// Shared
import 'shared/widgets/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Skip Firebase and complex service initialization for now
  // await Firebase.initializeApp();
  // await StorageService.init();
  // await NotificationService.init();
  
  runApp(const FertilityServicesApp());
}

class FertilityServicesApp extends StatelessWidget {
  const FertilityServicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SimpleAuthProvider(),
      child: Consumer<SimpleAuthProvider>(
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
          
          return MaterialApp(
            title: AppConfig.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            home: authProvider.isAuthenticated 
                ? const HomeScreen() 
                : const SimpleLoginScreen(),
          );
        },
      ),
    );
  }
}

// Simplified AuthProvider without Firebase dependencies
class SimpleAuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  SimpleAuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(seconds: 2));
    
    // For now, just set to not authenticated (show login)
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate login delay
    await Future.delayed(const Duration(seconds: 1));
    
    // For demo purposes, accept any login
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    notifyListeners();
  }
}

// Simple Login Screen that works with SimpleAuthProvider
class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({super.key});

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();
}

class _SimpleLoginScreenState extends State<SimpleLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              size: 64,
              color: Colors.pink,
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to Fertility Services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Consumer<SimpleAuthProvider>(
              builder: (context, authProvider, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () {
                            authProvider.login(
                              _emailController.text,
                              _passwordController.text,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter any email and password to login',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
