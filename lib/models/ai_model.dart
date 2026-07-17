class AIModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String category;
  final String categoryDisplay;
  final String inputType;
  final String inputTypeDisplay;
  final int runCount;
  final Map<String, dynamic>? inputSchema;

  const AIModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.category = '',
    this.categoryDisplay = '',
    this.inputType = '',
    this.inputTypeDisplay = '',
    this.runCount = 0,
    this.inputSchema,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) => AIModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        slug: (json['slug'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        categoryDisplay: (json['category_display'] ?? '').toString(),
        inputType: (json['input_type'] ?? '').toString(),
        inputTypeDisplay: (json['input_type_display'] ?? '').toString(),
        runCount: (json['run_count'] as num?)?.toInt() ?? 0,
        inputSchema:
            json['input_schema'] is Map ? Map<String, dynamic>.from(json['input_schema'] as Map) : null,
      );
}
