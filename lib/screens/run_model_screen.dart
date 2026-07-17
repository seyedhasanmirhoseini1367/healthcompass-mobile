import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';
import '../models/ai_model.dart';
import '../models/medical_record.dart';

class RunModelScreen extends StatefulWidget {
  final String modelSlug;
  const RunModelScreen({super.key, required this.modelSlug});
  @override
  State<RunModelScreen> createState() => _RunModelScreenState();
}

class _RunModelScreenState extends State<RunModelScreen> {
  AIModel? _model;
  bool _loadingModel = true;
  bool _running      = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      final data = await ApiService.aiModelDetail(widget.modelSlug);
      setState(() { _model = data; _loadingModel = false; });
      final schema = data.inputSchema ?? {};
      for (final key in schema.keys) {
        _controllers[key] = TextEditingController();
      }
    } catch (_) {
      setState(() { _error = 'Could not load model.'; _loadingModel = false; });
    }
  }

  Future<void> _submit() async {
    if (_model == null || !_formKey.currentState!.validate()) return;
    setState(() { _running = true; _error = null; });
    try {
      final inputData = <String, dynamic>{};
      for (final e in _controllers.entries) {
        inputData[e.key] = e.value.text.trim();
      }
      final result = await ApiService.runModel(widget.modelSlug, inputData);
      if (mounted) {
        if (result.id.isNotEmpty) {
          context.pushReplacement('/predictions/${result.id}');
        } else {
          setState(() { _error = 'Prediction created but no ID returned.'; _running = false; });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('400') ? 'Invalid input — check your values.' : 'Prediction failed. Please try again.';
        _running = false;
      });
    }
  }

  Future<void> _pickFromRecords() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _RecordPickerSheet(
        onRecordSelected: (record) async {
          Navigator.pop(ctx);
          await _fillFromRecord(record);
        },
      ),
    );
  }

  Future<void> _fillFromRecord(MedicalRecord record) async {
    try {
      final detail = await ApiService.recordDetail(record.id);
      final labValues = detail.labValues;
      final schema = _model!.inputSchema ?? {};
      int filled = 0;

      for (final key in schema.keys) {
        final fieldNorm = key.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        for (final lv in labValues) {
          final labNorm = lv.parameterName
              .toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (labNorm == fieldNorm ||
              labNorm.contains(fieldNorm) ||
              fieldNorm.contains(labNorm)) {
            final num = double.tryParse(lv.value);
            if (num != null) {
              _controllers[key]?.text = num == num.truncateToDouble()
                  ? num.toInt().toString()
                  : num.toStringAsFixed(2);
              filled++;
            }
            break;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(filled > 0
              ? 'Filled $filled field${filled > 1 ? "s" : ""} from "${record.title}"'
              : 'No matching fields found in this record'),
          backgroundColor: filled > 0 ? const Color(0xFF16a34a) : const Color(0xFFb45309),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not load record values'),
          backgroundColor: Color(0xFFef4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _fieldLabel(String key, dynamic schema) {
    if (schema is Map && (schema['label'] ?? '').toString().isNotEmpty) {
      return schema['label'].toString();
    }
    return key.replaceAll('_', ' ').split(' ').map((w) =>
        w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' ');
  }

  String? _fieldHint(String key, dynamic schema) {
    if (schema is Map) {
      final desc = schema['description'] ?? schema['hint'] ?? '';
      if (desc.toString().isNotEmpty) return desc.toString();
      final min = schema['min'];
      final max = schema['max'];
      if (min != null && max != null) return '$min – $max';
    }
    if (schema is String && schema.isNotEmpty) return schema;
    return null;
  }

  TextInputType _keyboardType(String key, dynamic schema) {
    if (schema is Map) {
      final type = (schema['type'] ?? '').toString().toLowerCase();
      if (type == 'integer' || type == 'float' || type == 'number') {
        return const TextInputType.numberWithOptions(decimal: true);
      }
    }
    final numericHints = ['age', 'bmi', 'glucose', 'cholesterol', 'pressure',
        'level', 'rate', 'count', 'score', 'value', 'weight', 'height'];
    if (numericHints.any((h) => key.toLowerCase().contains(h))) {
      return const TextInputType.numberWithOptions(decimal: true);
    }
    return TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    final cat       = (_model?.category.isEmpty ?? true) ? 'general' : _model!.category;
    final color     = _catColor(cat);
    final schema    = _model?.inputSchema ?? {};
    final inputType = (_model?.inputType.isEmpty ?? true) ? 'tabular' : _model!.inputType;
    final isTabular = inputType == 'tabular';

    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: Text((_model?.name.isEmpty ?? true) ? 'Run Model' : _model!.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
        actions: isTabular && schema.isNotEmpty ? [
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: 'Use from Records',
            onPressed: _loadingModel ? null : _pickFromRecords,
          ),
        ] : null,
      ),
      body: _loadingModel
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _error != null && _model == null
              ? Center(child: Text(_error!, style: const TextStyle(color: Color(0xFF64748b))))
              : _buildForm(color),
    );
  }

  Widget _buildForm(Color color) {
    final schema    = _model!.inputSchema ?? {};
    final inputType = _model!.inputType.isEmpty ? 'tabular' : _model!.inputType;
    final isTabular = inputType == 'tabular';

    if (!isTabular) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.upload_file_rounded, size: 56, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('File upload required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 10),
            Text(
              'This model requires a ${_model!.inputTypeDisplay.isEmpty ? 'file' : _model!.inputTypeDisplay} upload.\n'
              '${(inputType == 'parquet' || inputType == 'eeg_csv') ? 'Use the EEG Seizure Analysis screen for EEG files.' : 'Please use the website to run this model.'}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748b), height: 1.5),
            ),
            if (inputType == 'parquet' || inputType == 'eeg_csv') ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.push('/seizure-analysis'),
                icon: const Icon(Icons.biotech_rounded),
                label: const Text('Open EEG Analysis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b82f6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ]),
        ),
      );
    }

    if (schema.isEmpty) {
      return const Center(child: Text('This model has no input fields configured.',
          style: TextStyle(color: Color(0xFF64748b))));
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Model header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), Colors.white],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_model!.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(_model!.categoryDisplay,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
              if (_model!.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_model!.description,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5)),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          // From Records hint banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFf0f9ff),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFbae6fd)),
            ),
            child: const Row(children: [
              Icon(Icons.folder_open_rounded, color: Color(0xFF0284c7), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Tap  above to auto-fill fields from a saved lab record.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0369a1))),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          const Text('Enter your health data',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF64748b))),
          const SizedBox(height: 12),

          // Dynamic input fields
          ...schema.entries.map((e) {
            final key    = e.key;
            final fSchema = e.value;
            _controllers.putIfAbsent(key, () => TextEditingController());
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextFormField(
                controller: _controllers[key],
                keyboardType: _keyboardType(key, fSchema),
                decoration: InputDecoration(
                  labelText: _fieldLabel(key, fSchema),
                  hintText:  _fieldHint(key, fSchema),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            );
          }),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(10)),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFef4444), fontSize: 13)),
            ),
          ],

          const SizedBox(height: 8),
          const Text(
            'This AI prediction is for informational purposes only and does not constitute medical advice. Always consult a qualified healthcare professional.',
            style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _running ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _running
                  ? const SizedBox(height: 22, width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Run Prediction',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _catColor(String cat) {
    const colors = {
      'cardiovascular': Color(0xFFef4444),
      'diabetes':       Color(0xFFf59e0b),
      'oncology':       Color(0xFF8b5cf6),
      'neurology':      Color(0xFF3b82f6),
      'general':        Color(0xFF22c55e),
      'wearable':       Color(0xFF0ea5e9),
    };
    return colors[cat] ?? const Color(0xFF6366f1);
  }
}

// ── Record picker bottom sheet ────────────────────────────────────────────────

class _RecordPickerSheet extends StatefulWidget {
  final void Function(MedicalRecord) onRecordSelected;
  const _RecordPickerSheet({required this.onRecordSelected});
  @override
  State<_RecordPickerSheet> createState() => _RecordPickerSheetState();
}

class _RecordPickerSheetState extends State<_RecordPickerSheet> {
  List<MedicalRecord>? _records;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final records = await ApiService.records(type: 'lab_result');
      setState(() { _records = records; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Could not load records'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              const Icon(Icons.science_rounded, color: Color(0xFF0284c7), size: 20),
              const SizedBox(width: 8),
              const Text('Select a Lab Record',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20)),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Values are matched to model fields by name.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
                : _error != null
                    ? Center(child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFef4444))))
                    : _records!.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.science_outlined,
                                    size: 48, color: Color(0xFFcbd5e1)),
                                SizedBox(height: 12),
                                Text('No lab records found.\nUpload a lab result first.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xFF64748b))),
                              ]),
                            ))
                        : ListView.separated(
                            controller: ctrl,
                            itemCount: _records!.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 56),
                            itemBuilder: (_, i) {
                              final r = _records![i];
                              final date = r.recordDate ??
                                  r.uploadedAt?.substring(0, 10) ?? '';
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFe0f2fe),
                                  child: Icon(Icons.science_rounded,
                                      color: Color(0xFF0284c7), size: 18),
                                ),
                                title: Text(r.title.isEmpty ? 'Untitled' : r.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: date.isNotEmpty
                                    ? Text(date,
                                        style: const TextStyle(
                                            fontSize: 12, color: Color(0xFF64748b)))
                                    : null,
                                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 14, color: Color(0xFF94a3b8)),
                                onTap: () => widget.onRecordSelected(r),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
