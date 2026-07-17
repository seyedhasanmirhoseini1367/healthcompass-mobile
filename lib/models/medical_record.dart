class ParsedLabValue {
  final String parameterName;
  final String value;
  final String? unit;
  final String? referenceRange;
  final bool isAbnormal;
  final bool isCritical;
  final String? measuredAt;

  const ParsedLabValue({
    required this.parameterName,
    required this.value,
    this.unit,
    this.referenceRange,
    this.isAbnormal = false,
    this.isCritical = false,
    this.measuredAt,
  });

  factory ParsedLabValue.fromJson(Map<String, dynamic> json) => ParsedLabValue(
        parameterName: (json['parameter_name'] ?? '').toString(),
        value: (json['value'] ?? '').toString(),
        unit: json['unit']?.toString(),
        referenceRange: json['reference_range']?.toString(),
        isAbnormal: json['is_abnormal'] == true,
        isCritical: json['is_critical'] == true,
        measuredAt: json['measured_at']?.toString(),
      );
}

class WearableDataPoint {
  final String metric;
  final String? metricDisplay;
  final double? value;
  final String? unit;
  final String? recordedAt;

  const WearableDataPoint({
    required this.metric,
    this.metricDisplay,
    this.value,
    this.unit,
    this.recordedAt,
  });

  factory WearableDataPoint.fromJson(Map<String, dynamic> json) => WearableDataPoint(
        metric: (json['metric'] ?? '').toString(),
        metricDisplay: json['metric_display']?.toString(),
        value: (json['value'] as num?)?.toDouble(),
        unit: json['unit']?.toString(),
        recordedAt: json['recorded_at']?.toString(),
      );
}

class MedicalRecord {
  final String id;
  final String title;
  final String recordType;
  final String recordTypeDisplay;
  final String? recordDate;
  final String? uploadedAt;
  final bool isFlagged;
  final String notes;
  final Map<String, dynamic> parsedData;
  final String? rawText;
  final List<ParsedLabValue> labValues;
  final List<WearableDataPoint> wearablePoints;

  const MedicalRecord({
    required this.id,
    required this.title,
    required this.recordType,
    this.recordTypeDisplay = '',
    this.recordDate,
    this.uploadedAt,
    this.isFlagged = false,
    this.notes = '',
    this.parsedData = const {},
    this.rawText,
    this.labValues = const [],
    this.wearablePoints = const [],
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        recordType: (json['record_type'] ?? '').toString(),
        recordTypeDisplay: (json['record_type_display'] ?? '').toString(),
        recordDate: json['record_date']?.toString(),
        uploadedAt: json['uploaded_at']?.toString(),
        isFlagged: json['is_flagged'] == true,
        notes: (json['notes'] ?? '').toString(),
        parsedData: json['parsed_data'] is Map
            ? Map<String, dynamic>.from(json['parsed_data'] as Map)
            : const {},
        rawText: json['raw_text']?.toString(),
        labValues: (json['lab_values'] as List? ?? const [])
            .map((e) => ParsedLabValue.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        wearablePoints: (json['wearable_points'] as List? ?? const [])
            .map((e) => WearableDataPoint.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
