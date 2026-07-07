import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class AIModelsScreen extends StatefulWidget {
  const AIModelsScreen({super.key});
  @override
  State<AIModelsScreen> createState() => _AIModelsScreenState();
}

class _AIModelsScreenState extends State<AIModelsScreen> {
  List<dynamic> _models = [];
  bool _loading = true;
  bool _error   = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final data = await ApiService.aiModels();
      setState(() { _models = data; _loading = false; });
    } catch (_) {
      setState(() { _error = true; _loading = false; });
    }
  }

  static const _catColors = {
    'cardiovascular': Color(0xFFef4444),
    'diabetes':       Color(0xFFf59e0b),
    'oncology':       Color(0xFF8b5cf6),
    'neurology':      Color(0xFF3b82f6),
    'general':        Color(0xFF22c55e),
    'wearable':       Color(0xFF0ea5e9),
    'other':          Color(0xFF64748b),
  };

  static const _catIcons = {
    'cardiovascular': Icons.favorite_rounded,
    'diabetes':       Icons.water_drop_rounded,
    'oncology':       Icons.biotech_rounded,
    'neurology':      Icons.psychology_rounded,
    'general':        Icons.health_and_safety_rounded,
    'wearable':       Icons.watch_rounded,
    'other':          Icons.science_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('AI Models', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _error
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFcbd5e1)),
                  const SizedBox(height: 12),
                  const Text('Could not load models', style: TextStyle(color: Color(0xFF64748b))),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _models.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.psychology_outlined, size: 56, color: Color(0xFFcbd5e1)),
                      SizedBox(height: 12),
                      Text('No AI models available', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Models approved by admin\nwill appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 13)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _models.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _modelCard(_models[i]),
                      ),
                    ),
    );
  }

  Widget _modelCard(Map model) {
    final cat   = model['category'] ?? 'other';
    final color = _catColors[cat] ?? const Color(0xFF64748b);
    final icon  = _catIcons[cat]  ?? Icons.science_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(model['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(model['category_display'] ?? '', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFf0f7ff),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${model['run_count'] ?? 0} runs',
                style: const TextStyle(color: Color(0xFF64748b), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        if ((model['description'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(model['description'].toString(),
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFf1f5f9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(model['input_type_display'] ?? '',
                style: const TextStyle(color: Color(0xFF64748b), fontSize: 11)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/ai-models/${model['slug']}/run'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                model['input_type'] == 'tabular' ? 'Run Now' : 'View Details',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
