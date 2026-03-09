/// Global constants for the Friend Tracker application.
class AppConstants {
  AppConstants._();

  // ── API ──────────────────────────────────────────────────────────────────
  // Development settings
  static const String _devHost = '192.168.1.155'; // Change to your LAN IP if on physical device
  static const String _devBaseUrl = 'http://$_devHost:3000/api';
  
  // Production settings (update this with your Railway URL after deployment)
  static const String _prodBaseUrl = 'https://your-app-name.up.railway.app/api';
  
  // Use development URL for now, switch to production after deployment
  static const String baseUrl = _devBaseUrl;

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
