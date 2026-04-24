import 'package:flutter/material.dart';

enum ActivityType {
  protection,
  verification,
  piracyDetected,
  sync,
  error,
  alert,
}

/// Represents an activity event from the backend
class ActivityEvent {
  final String id;
  final String title;
  final String subtitle;
  final String timestamp;
  final ActivityType type;
  final Map<String, dynamic>? metadata;

  ActivityEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    this.metadata,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String?)?.toLowerCase() ?? 'alert';
    ActivityType type;

    switch (typeStr) {
      case 'protection':
        type = ActivityType.protection;
      case 'verification':
        type = ActivityType.verification;
      case 'piracy_detected':
        type = ActivityType.piracyDetected;
      case 'sync':
        type = ActivityType.sync;
      case 'error':
        type = ActivityType.error;
      default:
        type = ActivityType.alert;
    }

    return ActivityEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Event',
      subtitle: json['subtitle'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      type: type,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Get icon for activity type
  IconData get icon {
    switch (type) {
      case ActivityType.protection:
        return Icons.shield_rounded;
      case ActivityType.verification:
        return Icons.verified_user_rounded;
      case ActivityType.piracyDetected:
        return Icons.warning_rounded;
      case ActivityType.sync:
        return Icons.sync_rounded;
      case ActivityType.error:
        return Icons.error_rounded;
      case ActivityType.alert:
        return Icons.notifications_rounded;
    }
  }

  /// Get color for activity type
  Color get color {
    switch (type) {
      case ActivityType.protection:
        return const Color(0xFFA4C9FF); // primary
      case ActivityType.verification:
        return const Color(0xFF8ACEFF); // secondary
      case ActivityType.piracyDetected:
        return const Color(0xFF4A151A); // error
      case ActivityType.sync:
        return const Color(0xFF65AFFE); // tertiary
      case ActivityType.error:
        return const Color(0xFFFF6B6B);
      case ActivityType.alert:
        return const Color(0xFFFFB84D);
    }
  }

  /// Parse ISO timestamp to readable format
  String get readableTime {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) {
        return '${diff.inSeconds}s ago';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}
