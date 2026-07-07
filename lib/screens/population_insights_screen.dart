import 'package:flutter/material.dart';
import '../core/api_service.dart';

class PopulationInsightsScreen extends StatefulWidget {
  const PopulationInsightsScreen({super.key});
  @override
  State<PopulationInsightsScreen> createState() => _PopulationInsightsScreenState();
}

class _PopulationInsightsScreenState extends State<PopulationInsightsScreen> {
  Map<String, dynamic>? _data;
  bool   _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await ApiService.populationInsights();
      setState(() { _data = d; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Failed to load population data. Please try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Population Insights', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _error != null
              ? _errorView()
              : _body(),
    );
  }

  Widget _errorView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFF94a3b8)),
    const SizedBox(height: 12),
    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748b))),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: _load, child: const Text('Retry')),
  ]));

  Widget _body() {
    final d = _data!;
    final totalPatients = d['total_patients'] ?? 0;
    final avgRisk       = (d['average_risk_score'] ?? 0.0) as num;
    final biomarkers    = d['biomarker_averages'] as Map? ?? {};
    final riskBuckets   = d['risk_buckets'] as Map? ?? {};
    final alertsSummary = d['alerts_summary'] as Map? ?? {};
    final recordsByType = d['records_by_type'] as Map? ?? {};

    final riskTotal = (riskBuckets.values.fold<int>(0, (a, b) => a + (b as int? ?? 0)));
    final recordsTotal = (recordsByType.values.fold<int>(0, (a, b) => a + (b as int? ?? 0)));

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF0ea5e9),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header banner ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366f1), Color(0xFF0ea5e9)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 30)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Anonymous Population Data',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                Text('$totalPatients Patients',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                const Text('All data is anonymized and aggregated',
                    style: TextStyle(color: Colors.white60, fontSize: 11)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Average risk score ───────────────────────────────────────────
          _card(children: [
            _sectionHeader(Icons.monitor_heart_rounded, 'Average Risk Score', const Color(0xFFef4444)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(avgRisk.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF1e293b))),
                Text(_riskLabel(avgRisk.toDouble()),
                    style: TextStyle(color: _riskColor(avgRisk.toDouble()), fontWeight: FontWeight.w700, fontSize: 14)),
              ])),
              SizedBox(
                width: 70, height: 70,
                child: CircularProgressIndicator(
                  value: avgRisk / 100,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFe2e8f0),
                  color: _riskColor(avgRisk.toDouble()),
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 16),

          // ── Risk distribution ─────────────────────────────────────────────
          if (riskBuckets.isNotEmpty)
            _card(children: [
              _sectionHeader(Icons.bar_chart_rounded, 'Risk Distribution', const Color(0xFFf59e0b)),
              const SizedBox(height: 16),
              ...[ ['low', 'Low Risk', const Color(0xFF22c55e)],
                   ['moderate', 'Moderate Risk', const Color(0xFFf59e0b)],
                   ['high', 'High Risk', const Color(0xFFef4444)] ].map((entry) {
                final key   = entry[0] as String;
                final label = entry[1] as String;
                final color = entry[2] as Color;
                final count = riskBuckets[key] as int? ?? 0;
                final frac  = riskTotal > 0 ? count / riskTotal : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      Text('$count patients', style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
                      const SizedBox(width: 6),
                      Text('${(frac * 100).toStringAsFixed(1)}%',
                          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: frac, minHeight: 8,
                      backgroundColor: const Color(0xFFe2e8f0),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]),
                );
              }),
            ]),
          const SizedBox(height: 16),

          // ── Biomarker averages ────────────────────────────────────────────
          if (biomarkers.isNotEmpty)
            _card(children: [
              _sectionHeader(Icons.science_rounded, 'Population Biomarker Averages', const Color(0xFF0ea5e9)),
              const SizedBox(height: 16),
              ...biomarkers.entries.map((e) => _biomarkerRow(e.key, e.value)),
            ]),
          const SizedBox(height: 16),

          // ── Alerts summary ────────────────────────────────────────────────
          if (alertsSummary.isNotEmpty)
            _card(children: [
              _sectionHeader(Icons.notifications_active_rounded, 'Alerts Summary', const Color(0xFFef4444)),
              const SizedBox(height: 16),
              Row(children: [
                _statChip('Critical', alertsSummary['critical'] ?? 0, const Color(0xFFef4444)),
                const SizedBox(width: 10),
                _statChip('High',     alertsSummary['high']     ?? 0, const Color(0xFFf97316)),
                const SizedBox(width: 10),
                _statChip('Medium',   alertsSummary['medium']   ?? 0, const Color(0xFFf59e0b)),
                const SizedBox(width: 10),
                _statChip('Low',      alertsSummary['low']      ?? 0, const Color(0xFF22c55e)),
              ]),
            ]),
          const SizedBox(height: 16),

          // ── Records by type ───────────────────────────────────────────────
          if (recordsByType.isNotEmpty)
            _card(children: [
              _sectionHeader(Icons.folder_rounded, 'Records by Type', const Color(0xFF6366f1)),
              const SizedBox(height: 16),
              ...recordsByType.entries.map((e) {
                final frac = recordsTotal > 0 ? (e.value as int) / recordsTotal : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Expanded(child: Text(_formatType(e.key),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    Text('${e.value}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1e293b), fontSize: 13)),
                    const SizedBox(width: 8),
                    SizedBox(width: 80, child: LinearProgressIndicator(
                      value: frac, minHeight: 6,
                      backgroundColor: const Color(0xFFe2e8f0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366f1)),
                      borderRadius: BorderRadius.circular(3),
                    )),
                  ]),
                );
              }),
            ]),
          const SizedBox(height: 24),
          const Center(child: Text(
            'All data is anonymized. Individual patient data is never disclosed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11),
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _sectionHeader(IconData icon, String title, Color color) => Row(children: [
    Icon(icon, color: color, size: 20),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1e293b))),
  ]);

  Widget _biomarkerRow(String key, dynamic val) {
    final v = val is num ? val.toStringAsFixed(1) : val.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(
            color: Color(0xFF0ea5e9), shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(_formatKey(key),
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13))),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1e293b))),
      ]),
    );
  }

  Widget _statChip(String label, int count, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Column(children: [
      Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
    ]),
  ));

  String _riskLabel(double r) => r < 30 ? 'Low Risk' : r < 65 ? 'Moderate Risk' : 'High Risk';
  Color  _riskColor(double r) => r < 30 ? const Color(0xFF22c55e) : r < 65 ? const Color(0xFFf59e0b) : const Color(0xFFef4444);

  String _formatType(String t) => t.replaceAll('_', ' ')
      .split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

  String _formatKey(String k) => k.replaceAll('_', ' ')
      .split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
}
