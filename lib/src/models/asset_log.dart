
/// Represents a protected asset from the backend /logs endpoint
class AssetLog {
  final String filename;
  final String protectedAt;
  final double sizeKb;
  final String downloadUrl;
  final String? creatorFingerprint;
  final String? proofHash;
  final int? verificationCount;

  AssetLog({
    required this.filename,
    required this.protectedAt,
    required this.sizeKb,
    required this.downloadUrl,
    this.creatorFingerprint,
    this.proofHash,
    this.verificationCount,
  });

  factory AssetLog.fromJson(Map<String, dynamic> json) {
    return AssetLog(
      filename: json['filename'] as String,
      protectedAt: json['protected_at'] as String,
      sizeKb: (json['size_kb'] as num).toDouble(),
      downloadUrl: json['download_url'] as String,
      creatorFingerprint: json['creator_fingerprint'] as String?,
      proofHash: json['proof_hash'] as String?,
      verificationCount: json['verification_count'] as int?,
    );
  }

  /// Get file type from extension
  String get fileType {
    if (filename.endsWith('.mp4')) return 'Video';
    if (filename.endsWith('.png')) return 'Image';
    if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) return 'Image';
    return 'Unknown';
  }

  /// Get display filename (truncate if too long)
  String get displayFilename {
    if (filename.length > 40) {
      return '${filename.substring(0, 37)}...';
    }
    return filename;
  }

  /// Parse ISO timestamp to readable format
  String get readableTimestamp {
    try {
      final dt = DateTime.parse(protectedAt);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown time';
    }
  }

  /// Parse ISO timestamp to date string
  String get readableDate {
    try {
      final dt = DateTime.parse(protectedAt);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  /// Get relative time string (e.g., "2 hours ago")
  String get relativeTime {
    try {
      final dt = DateTime.parse(protectedAt);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) {
        return 'just now';
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
