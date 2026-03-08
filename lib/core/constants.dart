/// Global constants for the Friend Tracker application.
class AppConstants {
  AppConstants._();

  // ── API ──────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://example.com/api';

  // ── Storage keys ─────────────────────────────────────────────────────────
  static const String tokenKey = 'access_token';

  // ── Intervals ────────────────────────────────────────────────────────────
  /// How often (seconds) the app pushes its own location to the backend.
  static const int locationUpdateIntervalSeconds = 5;

  /// How often (seconds) the app refreshes friends' locations on the map.
  static const int mapRefreshIntervalSeconds = 10;
}
