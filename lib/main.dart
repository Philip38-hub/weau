import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/friend_provider.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FriendTrackerApp());
}

/// Root widget. Provides [ApiService] and both providers globally.
class FriendTrackerApp extends StatelessWidget {
  const FriendTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // A single ApiService instance is shared via Provider so every widget
    // (including MapScreen which also needs it for LocationTrackingService)
    // can access it without the Locator / GetIt pattern.
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        // Raw service — accessed by MapScreen to build LocationTrackingService.
        Provider<ApiService>(create: (_) => apiService),
        // Auth state.
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService: apiService)..checkAuth(),
        ),
        // Friends & invites state.
        ChangeNotifierProvider(
          create: (_) => FriendProvider(apiService: apiService),
        ),
      ],
      child: MaterialApp(
        title: 'weau',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(AppConstants.primaryColor),
            brightness: Brightness.dark,
            background: const Color(AppConstants.backgroundColor),
          ),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColor),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
