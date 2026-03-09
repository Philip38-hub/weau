import 'dart:async';
import 'dart:developer' as dev;
import 'package:geolocator/geolocator.dart';
import '../core/api_service.dart';
import '../core/constants.dart';

/// Background-ready service that sends the device's GPS position to
/// [POST /locations] every [AppConstants.locationUpdateIntervalSeconds] seconds
/// while active.
///
/// Lifecycle:
/// ```dart
/// final tracker = LocationTrackingService(apiService: _api);
/// await tracker.start();   // begin sending
/// tracker.stop();          // stop (e.g. on screen dispose / logout)
/// ```
///
/// The service requests location permissions on first start. If permissions
/// are denied it logs a warning and does not throw, so the rest of the app
/// continues to work without tracking.
class LocationTrackingService {
  final ApiService _api;
  Timer? _timer;
  bool _isRunning = false;

  LocationTrackingService({required ApiService apiService}) : _api = apiService;

  /// Whether the periodic upload is currently active.
  bool get isRunning => _isRunning;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Starts the 5-second location upload loop.
  ///
  /// Safe to call multiple times — calling [start] while already running is a
  /// no-op.
  Future<void> start() async {
    if (_isRunning) return;

    try {
      final position = await getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (position == null) return;

      _isRunning = true;
      // Fire once immediately, then on every tick.
      await _sendLocation(position);

      _timer = Timer.periodic(
        const Duration(seconds: AppConstants.locationUpdateIntervalSeconds),
        (_) => _uploadCurrentLocation(),
      );

      dev.log(
        'LocationTrackingService started '
        '(interval: ${AppConstants.locationUpdateIntervalSeconds}s).',
        name: 'LocationTrackingService',
      );
    } catch (e) {
      dev.log(
        'LocationTrackingService: initialization failed (plugin error): $e',
        name: 'LocationTrackingService',
      );
    }
  }

  /// Stops the periodic upload loop.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    dev.log('LocationTrackingService stopped.', name: 'LocationTrackingService');
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Returns the device's current position when location permission is granted.
  /// Falls back to the last known position if a live fix is temporarily slow.
  Future<Position?> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 10),
  }) async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      dev.log(
        'LocationTrackingService: permission denied — tracking disabled.',
        name: 'LocationTrackingService',
      );
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: desiredAccuracy,
          timeLimit: timeLimit,
        ),
      );
    } catch (e) {
      dev.log(
        'Falling back to last known position: $e',
        name: 'LocationTrackingService',
      );
      return Geolocator.getLastKnownPosition();
    }
  }

  /// Requests foreground location permission from the OS.
  /// Returns `true` if the permission is granted.
  Future<bool> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      dev.log(
        'Location services are disabled.',
        name: 'LocationTrackingService',
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Fetches the current device position and POSTs it to the backend.
  ///
  /// Errors are caught and logged so that a single failed upload doesn't
  /// cancel the entire periodic loop.
  Future<void> _uploadCurrentLocation() async {
    try {
      final position = await getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      if (position == null) return;

      await _sendLocation(position);
    } on ApiException catch (e) {
      dev.log(
        'Backend error uploading location: $e',
        name: 'LocationTrackingService',
        error: e,
      );
    } catch (e) {
      dev.log(
        'Unexpected error uploading location: $e',
        name: 'LocationTrackingService',
        error: e,
      );
    }
  }

  Future<void> _sendLocation(Position position) async {
    await _api.updateLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    dev.log(
      'Location uploaded: (${position.latitude}, ${position.longitude})',
      name: 'LocationTrackingService',
    );
  }
}
