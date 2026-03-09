/// Global constants for the Friend Tracker application.
class AppConstants {
  AppConstants._();

  // ── API ──────────────────────────────────────────────────────────────────
  // Use '10.0.2.2' for Android Emulator to hit localhost. 
  // For physical devices, replace with your LAN IP (e.g., '192.168.1.5').
  static const String _host = '192.168.1.155'; // Change to LAN IP if on physical device
  static const String baseUrl = 'http://$_host:3000/api';

  // ── Colors ───────────────────────────────────────────────────────────────
  static const int primaryColor = 0xFF6C63FF;
  static const int secondaryColor = 0xFF3F3D56;
  static const int accentColor = 0xFFFF6584;
  static const int backgroundColor = 0xFF0D0D1F;
  static const int glassColor = 0x1AFFFFFF;

  // ── Storage keys ─────────────────────────────────────────────────────────
  static const String tokenKey = 'access_token';
  static const String themeModeKey = 'theme_mode';

  // ── Intervals ────────────────────────────────────────────────────────────
  /// How often (seconds) the app pushes its own location to the backend.
  static const int locationUpdateIntervalSeconds = 5;

  /// How often (seconds) the app refreshes friends' locations on the map.
  static const int mapRefreshIntervalSeconds = 10;
}
