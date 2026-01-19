import 'verdict.dart';

class ScanResult {
  final String url;
  final Verdict verdict;
  final String details;
  final List<String> reasons;
  final DateTime timestamp;
  final int analysisTimeMs;

  ScanResult({
    required this.url,
    required this.verdict,
    required this.details,
    required this.reasons,
    required this.timestamp,
    required this.analysisTimeMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'verdict': verdict.name,
      'details': details,
      'reasons': reasons,
      'timestamp': timestamp.toIso8601String(),
      'analysisTimeMs': analysisTimeMs,
    };
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      url: json['url'],
      verdict: Verdict.values.firstWhere((e) => e.name == json['verdict']),
      details: json['details'],
      reasons: List<String>.from(json['reasons']),
      timestamp: DateTime.parse(json['timestamp']),
      analysisTimeMs: json['analysisTimeMs'],
    );
  }
}
