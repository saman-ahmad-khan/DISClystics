class DiscQuestion {
  final int group;
  final String text;
  final Map<String, int> most;
  final Map<String, int> least;

  const DiscQuestion({
    required this.group,
    required this.text,
    required this.most,
    required this.least,
  });
}

class DiscResult {
  final Map<String, double> internal;
  final Map<String, double> external;
  final Map<String, double> summary;
  final Map<String, double> shift;

  DiscResult({
    required this.internal,
    required this.external,
    required this.summary,
    required this.shift,
  });

  /// Convert to map (e.g. for Firestore saving)
  Map<String, dynamic> toMap() {
    return {
      'internal': internal,
      'external': external,
      'summary': summary,
      'shift': shift,
    };
  }

  /// Create from Firestore map
  factory DiscResult.fromMap(Map<String, dynamic> map) {
    return DiscResult(
      internal: Map<String, double>.from(map['internal'] ?? {}),
      external: Map<String, double>.from(map['external'] ?? {}),
      summary: Map<String, double>.from(map['summary'] ?? {}),
      shift: Map<String, double>.from(map['shift'] ?? {}),
    );
  }

  /// Optional: Create from integer maps
  factory DiscResult.fromIntegerMaps(
      Map<String, int> internal,
      Map<String, int> external,
      Map<String, int> summary,
      Map<String, int> shift,
      ) {
    return DiscResult(
      internal: internal.map((k, v) => MapEntry(k, v.toDouble())),
      external: external.map((k, v) => MapEntry(k, v.toDouble())),
      summary: summary.map((k, v) => MapEntry(k, v.toDouble())),
      shift: shift.map((k, v) => MapEntry(k, v.toDouble())),
    );
  }
}
