class PiracyAlert {
  final String id;
  final String creatorFingerprint;
  final String timestamp;
  final String sourceUrl;
  final String confidence;
  final String tier;
  final String? dmcaDraft;
  final String status;

  PiracyAlert({
    required this.id,
    required this.creatorFingerprint,
    required this.timestamp,
    required this.sourceUrl,
    required this.confidence,
    required this.tier,
    this.dmcaDraft,
    required this.status,
  });

  factory PiracyAlert.fromJson(Map<String, dynamic> json) {
    return PiracyAlert(
      id: json['id'],
      creatorFingerprint: json['creator_fingerprint'],
      timestamp: json['timestamp'],
      sourceUrl: json['source_url'],
      confidence: json['confidence'],
      tier: json['tier'],
      dmcaDraft: json['dmca_draft'],
      status: json['status'],
    );
  }
}
