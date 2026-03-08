import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // add when ready
import '../providers/auth_provider.dart';
import 'map_screen.dart';

/// Sign-in screen. Calls [AuthProvider.signIn] with a Google id_token.
///
/// Replace the TODO section below with the actual Google Sign-In flow once
/// `google_sign_in` is added to pubspec.yaml.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _signingIn = false;

  Future<void> _handleSignIn() async {
    setState(() => _signingIn = true);
    try {
      // ── TODO: Replace with real Google Sign-In ────────────────────────────
      // final googleUser = await GoogleSignIn().signIn();
      // if (googleUser == null) return; // user cancelled
      // final auth = await googleUser.authentication;
      // final idToken = auth.idToken!;
      // ─────────────────────────────────────────────────────────────────────
      // DEMO: use a placeholder token until Google Sign-In is integrated.
      const idToken = 'REPLACE_WITH_REAL_GOOGLE_ID_TOKEN';

      final authProvider = context.read<AuthProvider>();
      await authProvider.signIn(idToken: idToken);

      if (!mounted) return;
      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      } else if (authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error!)),
        );
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt, size: 80, color: Colors.indigo),
                const SizedBox(height: 24),
                Text(
                  'weau',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'See where your friends are in real-time.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _signingIn
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _handleSignIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
