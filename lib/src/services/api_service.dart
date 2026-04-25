import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/asset_log.dart';
import '../models/activity_event.dart';
import '../models/protection_stats.dart';
import '../models/alert.dart';

/// HTTP service for communicating with the INDELIBLE backend API.
///
/// Handles:
/// - Fetching real asset logs from /logs
/// - Converting JSON responses to typed Dart models
/// - Error handling and caching
/// - Base URL management
class ApiService {
  static const String baseUrl = 'https://indelible.up.railway.app';
  static const Duration _cacheDuration = Duration(seconds: 30);

  // Simple in-memory cache
  static final Map<String, _CacheEntry> _cache = {};

  /// Fetch all protected assets from the backend
  Future<List<AssetLog>> fetchAssetLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/logs'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final logs = data['logs'] as List<dynamic>? ?? [];
        return logs
            .map((item) => AssetLog.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching asset logs: $e');
    }
  }

  /// Fetch protection statistics
  /// Returns mocked stats until backend provides an endpoint
  Future<ProtectionStats> fetchProtectionStats() async {
    try {
      // For now, return computed stats from asset logs
      final logs = await fetchAssetLogs();
      
      return ProtectionStats(
        totalAssets: logs.length,
        successfulVerifications: (logs.length * 0.95).toInt(),
        failedVerifications: (logs.length * 0.05).toInt(),
        totalStorageMb: logs.fold(0.0, (sum, log) => sum + log.sizeKb) / 1024,
        uptimePercentage: 99.8,
        averageProtectionTimeSeconds: 2.5,
        pirancyIncidentsThisMonth: 3,
      );
    } catch (e) {
      throw Exception('Error fetching protection stats: $e');
    }
  }

  /// Fetch recent activity events
  /// Returns activity based on asset logs and simulated events
  Future<List<ActivityEvent>> fetchActivityEvents({int limit = 10}) async {
    try {
      final logs = await fetchAssetLogs();
      final events = <ActivityEvent>[];

      // Convert asset logs to protection events
      for (var i = 0; i < logs.length && i < limit; i++) {
        final log = logs[i];
        events.add(
          ActivityEvent(
            id: 'EVT-${i + 1}',
            title: 'Asset Protected Successfully',
            subtitle: 'File "${log.displayFilename}" secured with watermark',
            timestamp: log.protectedAt,
            type: ActivityType.protection,
            metadata: {
              'filename': log.filename,
              'size_kb': log.sizeKb,
            },
          ),
        );
      }

      // Sort by timestamp descending
      events.sort((a, b) => DateTime.parse(b.timestamp)
          .compareTo(DateTime.parse(a.timestamp)));

      return events.take(limit).toList();
    } catch (e) {
      throw Exception('Error fetching activity events: $e');
    }
  }

  /// Fetch piracy alerts for the current user
  Future<List<PiracyAlert>> fetchAlerts(String userUid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/alerts/$userUid'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final alerts = data['alerts'] as List<dynamic>? ?? [];
        return alerts
            .map((item) => PiracyAlert.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch alerts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching alerts: $e');
    }
  }

  /// Check if backend is accessible
  Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/logs'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Get single cached entry or null if expired
  static T? _getCached<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > _cacheDuration) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// Set cache entry
  static void _setCached<T>(String key, T value) {
    _cache[key] = _CacheEntry(value, DateTime.now());
  }
}

/// Simple cache entry with timestamp
class _CacheEntry {
  final dynamic value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}
