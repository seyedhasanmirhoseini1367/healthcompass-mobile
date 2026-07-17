class Prediction {
  final String id;
  final String modelName;
  final String modelCategory;
  final String modelSlug;
  final double? riskScore;
  final double? riskPct;
  final String resultLabel;
  final String interpretation;
  final Map<String, dynamic> result;
  final Map<String, dynamic> inputData;
  final String? createdAt;

  const Prediction({
    required this.id,
    this.modelName = '',
    this.modelCategory = '',
    this.modelSlug = '',
    this.riskScore,
    this.riskPct,
    this.resultLabel = '',
    this.interpretation = '',
    this.result = const {},
    this.inputData = const {},
    this.createdAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
        id: (json['id'] ?? '').toString(),
        modelName: (json['model_name'] ?? '').toString(),
        modelCategory: (json['model_category'] ?? '').toString(),
        modelSlug: (json['model_slug'] ?? '').toString(),
        riskScore: (json['risk_score'] as num?)?.toDouble(),
        riskPct: (json['risk_pct'] as num?)?.toDouble(),
        resultLabel: (json['result_label'] ?? '').toString(),
        interpretation: (json['interpretation'] ?? '').toString(),
        result: json['result'] is Map ? Map<String, dynamic>.from(json['result'] as Map) : const {},
        inputData:
            json['input_data'] is Map ? Map<String, dynamic>.from(json['input_data'] as Map) : const {},
        createdAt: json['created_at']?.toString(),
      );
}
