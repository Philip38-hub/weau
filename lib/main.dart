import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          create: (_) => AuthProvider(apiService: apiService),
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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
