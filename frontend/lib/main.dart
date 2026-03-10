import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/app_theme.dart';
import 'core/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();
  runApp(FriendTrackerApp(themeProvider: themeProvider));
}

/// Root widget. Provides [ApiService] and both providers globally.
class FriendTrackerApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const FriendTrackerApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    // A single ApiService instance is shared via Provider so every widget
    // (including MapScreen which also needs it for LocationTrackingService)
    // can access it without the Locator / GetIt pattern.
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        // Raw service — accessed by MapScreen to build LocationTrackingService.
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        // Auth state.
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService: apiService)..checkAuth(),
        ),
        // Friends & invites state.
        ChangeNotifierProvider(
          create: (_) => FriendProvider(apiService: apiService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'weau',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.themeMode,
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
