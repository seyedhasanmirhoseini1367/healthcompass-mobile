import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});
  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _error   = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final data = await ApiService.myPredictions();
      setState(() { _items = data; _loading = false; });
    } catch (_) {
      setState(() { _error = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('My AI Predictions', style: TextStyle(fontWeight: FontWeight.w800)),
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
                  const Text('Could not load predictions', style: TextStyle(color: Color(0xFF64748b))),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _items.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.psychology_outlined, size: 56, color: Color(0xFFcbd5e1)),
                      SizedBox(height: 12),
                      Text('No predictions yet', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Run an AI model to see predictions here',
                          style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 13)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _card(_items[i]),
                      ),
                    ),
    );
  }

  Widget _card(Map pred) {
    final risk  = (pred['risk_pct'] as num?)?.toDouble();
    final label = pred['result_label'] ?? '';
    final model = pred['model_name'] ?? 'AI Model';
    final color = risk == null ? const Color(0xFF64748b)
        : risk >= 70 ? const Color(0xFFef4444)
        : risk >= 40 ? const Color(0xFFf59e0b)
        : const Color(0xFF22c55e);

    return InkWell(
      onTap: () => context.push('/predictions/${pred['id']}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFe2e8f0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.psychology_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(model, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(_timeAgo(pred['created_at']),
                  style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 11)),
            ])),
            if (risk != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${risk.toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 18)),
                const Text('risk', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11)),
              ]),
          ]),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ],
          if (risk != null) ...[
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: risk / 100,
                  backgroundColor: const Color(0xFFf1f5f9), color: color, minHeight: 5)),
          ],
          const SizedBox(height: 8),
          const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('View details', style: TextStyle(color: Color(0xFF0ea5e9), fontSize: 12, fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Color(0xFF0ea5e9), size: 16),
          ]),
        ]),
      ),
    );
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
}
