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
  // only uncomment it for testing on local machine

  static const String baseUrl = 'http://localhost:8000';

  // static const String baseUrl = 'https://indelible.up.railway.app';

  // Simple in-memory cache
  static final Map<String, _CacheEntry> _cache = {};

  /// Fetch all protected assets from the backend
  Future<List<AssetLog>> fetchAssetLogs({String? userUid}) async {
    try {
      final url = userUid != null
          ? '$baseUrl/logs?user_uid=$userUid'
          : '$baseUrl/logs';
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

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
  Future<ProtectionStats> fetchProtectionStats({String? userUid}) async {
    try {
      // For now, return computed stats from asset logs
      final logs = await fetchAssetLogs(userUid: userUid);
      
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
  Future<List<ActivityEvent>> fetchActivityEvents({int limit = 10, String? userUid}) async {
    try {
      final logs = await fetchAssetLogs(userUid: userUid);
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
            metadata: {'filename': log.filename, 'size_kb': log.sizeKb},
          ),
        );
      }

      // Sort by timestamp descending
      events.sort(
        (a, b) =>
            DateTime.parse(b.timestamp).compareTo(DateTime.parse(a.timestamp)),
      );

      return events.take(limit).toList();
    } catch (e) {
      throw Exception('Error fetching activity events: $e');
    }
  }

  /// Fetch piracy alerts for the current user
  Future<List<PiracyAlert>> fetchAlerts(String userUid) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/alerts/$userUid'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

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

  /// Fetch real weekly activity bar chart data from /dashboard-stats
  Future<Map<String, dynamic>> fetchDashboardStats({String? userUid}) async {
    try {
      final url = userUid != null
          ? '$baseUrl/dashboard-stats?user_uid=$userUid'
          : '$baseUrl/dashboard-stats';
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'labels': ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'], 'bars': [0,0,0,0,0,0,0], 'total_events': 0};
    } catch (e) {
      return {'labels': ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'], 'bars': [0,0,0,0,0,0,0], 'total_events': 0};
    }
  }

  /// Fetch crawl-scan results — leaked asset detections from the web crawler
  Future<Map<String, dynamic>> fetchCrawlResults({String userUid = 'anonymous'}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/crawl-scan?user_uid=$userUid'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'leaks': [], 'leaks_found': 0};
    } catch (e) {
      return {'leaks': [], 'leaks_found': 0};
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
}

/// Simple cache entry with timestamp
class _CacheEntry {
  final dynamic value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}
