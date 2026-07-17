import 'dart:convert';

/// A cited medical record (or general-knowledge article) backing an
/// assistant reply. Two shapes come from the backend:
///   personal record → {title, document_type, record_date, document_id, record_id}
///   general article  → {title, source_name, source_url, topic, is_general: true}
class SourceRef {
  final String title;
  final String? documentType;
  final String? recordDate;
  final String? documentId;
  final String? recordId;
  final bool isGeneral;
  final String? sourceName;
  final String? sourceUrl;
  final String? topic;

  const SourceRef({
    required this.title,
    this.documentType,
    this.recordDate,
    this.documentId,
    this.recordId,
    this.isGeneral = false,
    this.sourceName,
    this.sourceUrl,
    this.topic,
  });

  factory SourceRef.fromJson(Map<String, dynamic> json) => SourceRef(
        title: (json['title'] ?? 'Record').toString(),
        documentType: json['document_type']?.toString(),
        recordDate: json['record_date']?.toString(),
        documentId: json['document_id']?.toString(),
        recordId: json['record_id']?.toString(),
        isGeneral: json['is_general'] == true,
        sourceName: json['source_name']?.toString(),
        sourceUrl: json['source_url']?.toString(),
        topic: json['topic']?.toString(),
      );
}

/// Chart.js-ready biomarker trend payload from `TrajectoryService.get_chart_data()`.
class ChartPayload {
  final String biomarker;
  final String displayName;
  final String unit;
  final List<String> labels;
  final List<double> values;
  final String trendDirection; // INCREASING | DECREASING | STABLE
  final double pctChange;
  final double slopePerMonth;
  final double? referenceLow;
  final double? referenceHigh;

  const ChartPayload({
    required this.biomarker,
    required this.displayName,
    required this.unit,
    required this.labels,
    required this.values,
    required this.trendDirection,
    required this.pctChange,
    required this.slopePerMonth,
    this.referenceLow,
    this.referenceHigh,
  });

  factory ChartPayload.fromJson(Map<String, dynamic> json) => ChartPayload(
        biomarker: (json['biomarker'] ?? '').toString(),
        displayName: (json['display_name'] ?? '').toString(),
        unit: (json['unit'] ?? '').toString(),
        labels: List<String>.from((json['labels'] as List? ?? const []).map((e) => e.toString())),
        values: List<double>.from(
            (json['values'] as List? ?? const []).map((e) => (e as num).toDouble())),
        trendDirection: (json['trend_direction'] ?? 'STABLE').toString(),
        pctChange: ((json['pct_change'] ?? 0) as num).toDouble(),
        slopePerMonth: ((json['slope_per_month'] ?? 0) as num).toDouble(),
        referenceLow: (json['reference_low'] as num?)?.toDouble(),
        referenceHigh: (json['reference_high'] as num?)?.toDouble(),
      );
}

enum ChatEventType { token, sources, meta, chart, done, error, unknown }

/// One parsed line from the `/assistant/stream/` SSE response.
class ChatEvent {
  final ChatEventType type;
  final String? content; // token
  final List<SourceRef>? sources; // sources
  final ChartPayload? chart; // chart
  final String? provider; // meta
  final int? chunks; // meta
  final String? mode; // meta
  final String? errorMessage; // error

  const ChatEvent._({
    required this.type,
    this.content,
    this.sources,
    this.chart,
    this.provider,
    this.chunks,
    this.mode,
    this.errorMessage,
  });

  static ChatEventType _typeOf(String? raw) {
    switch (raw) {
      case 'token':
        return ChatEventType.token;
      case 'sources':
        return ChatEventType.sources;
      case 'meta':
        return ChatEventType.meta;
      case 'chart':
        return ChatEventType.chart;
      case 'done':
        return ChatEventType.done;
      case 'error':
        return ChatEventType.error;
      default:
        return ChatEventType.unknown;
    }
  }

  /// Parses one raw SSE line (e.g. `data: {"type": "token", ...}`).
  /// Returns null for blank lines, comments, or anything that isn't a
  /// well-formed `data:` JSON event — callers should skip those silently.
  static ChatEvent? parseSseLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data:')) return null;
    final jsonStr = trimmed.substring(5).trim();
    if (jsonStr.isEmpty) return null;

    Map<String, dynamic> payload;
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is! Map<String, dynamic>) return null;
      payload = decoded;
    } catch (_) {
      return null;
    }

    final type = _typeOf(payload['type']?.toString());
    switch (type) {
      case ChatEventType.token:
        return ChatEvent._(type: type, content: payload['content']?.toString() ?? '');
      case ChatEventType.sources:
        final list = (payload['sources'] as List? ?? const [])
            .map((e) => SourceRef.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return ChatEvent._(type: type, sources: list);
      case ChatEventType.meta:
        return ChatEvent._(
          type: type,
          provider: payload['provider']?.toString(),
          chunks: (payload['chunks'] as num?)?.toInt(),
          mode: payload['mode']?.toString(),
        );
      case ChatEventType.chart:
        final chartJson = payload['chart'];
        if (chartJson == null) return ChatEvent._(type: type);
        return ChatEvent._(
            type: type, chart: ChartPayload.fromJson(Map<String, dynamic>.from(chartJson as Map)));
      case ChatEventType.done:
        return ChatEvent._(type: type);
      case ChatEventType.error:
        return ChatEvent._(
            type: type, errorMessage: payload['message']?.toString() ?? 'Unknown error');
      case ChatEventType.unknown:
        return null;
    }
  }
}
