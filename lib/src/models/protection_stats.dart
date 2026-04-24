/// Represents protection metrics from the backend
class ProtectionStats {
  /// Total number of assets protected
  final int totalAssets;

  /// Total number of successful verifications
  final int successfulVerifications;

  /// Total number of failed verifications
  final int failedVerifications;

  /// Total storage used in MB
  final double totalStorageMb;

  /// Uptime percentage (0-100)
  final double uptimePercentage;

  /// Average protection time in seconds
  final double averageProtectionTimeSeconds;

  /// Number of piracy incidents detected this month
  final int pirancyIncidentsThisMonth;

  ProtectionStats({
    required this.totalAssets,
    required this.successfulVerifications,
    required this.failedVerifications,
    required this.totalStorageMb,
    required this.uptimePercentage,
    required this.averageProtectionTimeSeconds,
    required this.pirancyIncidentsThisMonth,
  });

  factory ProtectionStats.fromJson(Map<String, dynamic> json) {
    return ProtectionStats(
      totalAssets: json['total_assets'] as int? ?? 0,
      successfulVerifications: json['successful_verifications'] as int? ?? 0,
      failedVerifications: json['failed_verifications'] as int? ?? 0,
      totalStorageMb: (json['total_storage_mb'] as num?)?.toDouble() ?? 0.0,
      uptimePercentage: (json['uptime_percentage'] as num?)?.toDouble() ?? 99.8,
      averageProtectionTimeSeconds:
          (json['average_protection_time_seconds'] as num?)?.toDouble() ?? 2.5,
      pirancyIncidentsThisMonth:
          json['piracy_incidents_this_month'] as int? ?? 0,
    );
  }

  /// Calculate verification success rate percentage
  double get successRate {
    final total = successfulVerifications + failedVerifications;
    if (total == 0) return 0.0;
    return (successfulVerifications / total) * 100;
  }

  /// Get human-readable storage used
  String get storageDisplay {
    if (totalStorageMb > 1024) {
      return '${(totalStorageMb / 1024).toStringAsFixed(1)} GB';
    }
    return '${totalStorageMb.toStringAsFixed(1)} MB';
  }
}
