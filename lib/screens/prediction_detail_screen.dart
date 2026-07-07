import 'package:flutter/material.dart';
import '../core/api_service.dart';

class PredictionDetailScreen extends StatefulWidget {
  final String predictionId;
  const PredictionDetailScreen({super.key, required this.predictionId});
  @override
  State<PredictionDetailScreen> createState() => _PredictionDetailScreenState();
}

class _PredictionDetailScreenState extends State<PredictionDetailScreen> {
  Map<String, dynamic>? _pred;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.predictionDetail(widget.predictionId);
      setState(() { _pred = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final risk  = (_pred?['risk_pct'] as num?)?.toDouble();
    final color = risk == null ? const Color(0xFF64748b)
        : risk >= 70 ? const Color(0xFFef4444)
        : risk >= 40 ? const Color(0xFFf59e0b)
        : const Color(0xFF22c55e);

    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Prediction Result', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _pred == null
              ? const Center(child: Text('Not found.', style: TextStyle(color: Color(0xFF64748b))))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Risk gauge card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), Colors.white],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Column(children: [
                        Text(_pred!['model_name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1e293b)),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        if (risk != null) ...[
                          Stack(alignment: Alignment.center, children: [
                            SizedBox(height: 100, width: 100,
                              child: CircularProgressIndicator(
                                value: risk / 100,
                                strokeWidth: 10,
                                backgroundColor: const Color(0xFFf1f5f9),
                                color: color,
                              ),
                            ),
                            Text('${risk.toStringAsFixed(1)}%',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                          ]),
                          const SizedBox(height: 12),
                          Text(
                            risk >= 70 ? 'High Risk' : risk >= 40 ? 'Moderate Risk' : 'Low Risk',
                            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ] else if ((_pred!['result_label'] ?? '').isNotEmpty)
                          Text(_pred!['result_label'],
                              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
                      ]),
                    ),

                    const SizedBox(height: 14),

                    // Interpretation
                    if ((_pred!['interpretation'] ?? '').toString().isNotEmpty)
                      _section('AI Interpretation', Icons.psychology_rounded, const Color(0xFF6366f1),
                          _pred!['interpretation'].toString()),

                    const SizedBox(height: 14),

                    // Input data
                    if ((_pred!['input_data'] as Map?)?.isNotEmpty == true)
                      _jsonSection('Your Inputs', Icons.input_rounded, const Color(0xFF0ea5e9),
                          _pred!['input_data'] as Map),

                    const SizedBox(height: 14),

                    // Result details
                    if ((_pred!['result'] as Map?)?.isNotEmpty == true)
                      _jsonSection('Model Output', Icons.analytics_rounded, const Color(0xFF22c55e),
                          _pred!['result'] as Map),

                    const SizedBox(height: 14),
                    Center(child: Text(
                      'This prediction is AI-generated and is not a medical diagnosis.\nAlways consult a qualified healthcare professional.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 11, height: 1.5),
                    )),
                  ],
                ),
    );
  }

  Widget _section(String title, IconData icon, Color color, String content) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1e293b))),
      ]),
      const SizedBox(height: 12),
      Text(content, style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.6)),
    ]),
  );

  Widget _jsonSection(String title, IconData icon, Color color, Map data) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1e293b))),
      ]),
      const SizedBox(height: 12),
      ...data.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).map((e) =>
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Text(e.key,
                style: const TextStyle(color: Color(0xFF64748b), fontSize: 12))),
            Expanded(flex: 3, child: Text(e.value.toString(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1e293b)))),
          ],
        ))),
    ]),
  );
}
