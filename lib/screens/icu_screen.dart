import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/api_service.dart';

class IcuScreen extends StatefulWidget {
  const IcuScreen({super.key});
  @override
  State<IcuScreen> createState() => _IcuScreenState();
}

class _IcuScreenState extends State<IcuScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _error   = false;
  String _activeVital = 'hr';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final d = await ApiService.icuDashboard();
      setState(() { _data = d; _loading = false; });
    } catch (_) {
      setState(() { _error = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('ICU Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFFef4444),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Demo · MIMIC-IV',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFef4444)))
          : _error
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFcbd5e1)),
    const SizedBox(height: 12),
    const Text('Could not load ICU data', style: TextStyle(color: Color(0xFF64748b))),
    const SizedBox(height: 16),
    ElevatedButton(
      onPressed: _load,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFef4444), foregroundColor: Colors.white),
      child: const Text('Retry'),
    ),
  ]));

  Widget _buildContent() {
    final d       = _data!;
    final patient = d['patient'] as Map? ?? {};
    final sofa    = (d['sofa'] as List? ?? []).cast<Map>();
    final sofaTotal = d['sofa_total'] ?? 0;
    final vitals  = (d['vitals'] as Map? ?? {}).cast<String, dynamic>();
    final labs    = (d['labs']   as Map? ?? {}).cast<String, dynamic>();
    final labSnap = (d['lab_snap'] as List? ?? []).cast<Map>();
    final events  = (d['events']  as List? ?? []).cast<Map>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _patientCard(patient),
        const SizedBox(height: 14),
        _sofaCard(sofa, sofaTotal),
        const SizedBox(height: 14),
        _vitalsCard(vitals),
        const SizedBox(height: 14),
        _labSnapCard(labSnap),
        const SizedBox(height: 14),
        _labTrendsCard(labs),
        const SizedBox(height: 14),
        _eventsCard(events),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFfef9c3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFfde047)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFca8a04)),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Demo data from MIMIC-IV (de-identified). For educational purposes only.',
              style: TextStyle(fontSize: 11, color: Color(0xFF92400e)),
            )),
          ]),
        ),
      ],
    );
  }

  // ── Patient card ─────────────────────────────────────────────────────────────

  Widget _patientCard(Map patient) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDeco(),
    child: Row(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFef4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: Text('🏥', style: TextStyle(fontSize: 26))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Patient #${patient['subject_id']}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1e293b))),
        Text('${patient['age']} yr · ${patient['gender']} · ${patient['unit']}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748b))),
        const SizedBox(height: 4),
        Wrap(spacing: 6, children: [
          _chip('LOS ${patient['los_days']}d',       const Color(0xFF0ea5e9)),
          _chip(patient['admission_type'] ?? '',     const Color(0xFF6366f1)),
          _chip(patient['outcome'] ?? '',
              patient['outcome'] == 'Deceased' ? const Color(0xFFef4444) : const Color(0xFF22c55e)),
        ]),
      ])),
    ]),
  );

  // ── SOFA card ────────────────────────────────────────────────────────────────

  Widget _sofaCard(List<Map> sofa, int total) {
    final color = total >= 11 ? const Color(0xFFef4444)
        : total >= 7  ? const Color(0xFFf59e0b)
        : const Color(0xFF22c55e);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('SOFA Score', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text('$total / 24',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(total >= 11 ? 'High organ failure — critical' : total >= 7 ? 'Moderate organ failure' : 'Low organ failure',
            style: TextStyle(fontSize: 12, color: color)),
        const SizedBox(height: 14),
        ...sofa.map((s) {
          final score = (s['score'] as num).toInt();
          final max   = (s['max']   as num).toInt();
          final c     = score >= 3 ? const Color(0xFFef4444)
              : score >= 2 ? const Color(0xFFf59e0b)
              : score >= 1 ? const Color(0xFF0ea5e9)
              : const Color(0xFF22c55e);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(s['organ'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('$score/$max', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / max,
                  backgroundColor: const Color(0xFFf1f5f9),
                  color: c, minHeight: 7,
                )),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Vitals chart ─────────────────────────────────────────────────────────────

  static const _vitalMeta = {
    'hr':   {'label': 'Heart Rate',  'unit': 'bpm',   'color': Color(0xFFef4444)},
    'map':  {'label': 'MAP',         'unit': 'mmHg',  'color': Color(0xFF6366f1)},
    'spo2': {'label': 'SpO₂',        'unit': '%',     'color': Color(0xFF0ea5e9)},
    'rr':   {'label': 'Resp Rate',   'unit': 'br/min','color': Color(0xFF22c55e)},
  };

  Widget _vitalsCard(Map<String, dynamic> vitals) {
    final meta   = _vitalMeta[_activeVital]!;
    final pts    = (vitals[_activeVital] as List? ?? []);
    final spots  = pts.asMap().entries.map((e) {
      final row = e.value as List;
      return FlSpot((row[0] as num).toDouble(), (row[1] as num).toDouble());
    }).toList();
    final color  = meta['color'] as Color;
    final minY   = spots.isEmpty ? 0.0 : spots.map((s) => s.y).reduce((a,b) => a<b?a:b);
    final maxY   = spots.isEmpty ? 1.0 : spots.map((s) => s.y).reduce((a,b) => a>b?a:b);
    final pad    = (maxY - minY) * 0.2 + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Vitals', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 12),
        // Selector pills
        SizedBox(
          height: 32,
          child: ListView(scrollDirection: Axis.horizontal, children: _vitalMeta.entries.map((e) {
            final sel = e.key == _activeVital;
            final c   = e.value['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _activeVital = e.key),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? c : const Color(0xFFf1f5f9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(e.value['label'] as String,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFF475569))),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 12),
        if (spots.length >= 2)
          SizedBox(
            height: 160,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFf1f5f9), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 38,
                  getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 9, color: Color(0xFF94a3b8))),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  interval: 5,
                  getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)}s',
                      style: const TextStyle(fontSize: 9, color: Color(0xFF94a3b8))),
                )),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: minY - pad, maxY: maxY + pad,
              lineBarsData: [LineChartBarData(
                spots: spots, isCurved: true,
                color: color, barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true,
                    color: color.withValues(alpha: 0.08)),
              )],
            )),
          )
        else
          const Center(child: Text('No data', style: TextStyle(color: Color(0xFF94a3b8)))),
        const SizedBox(height: 6),
        Text('Unit: ${meta['unit']}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
      ]),
    );
  }

  // ── Lab snapshot ─────────────────────────────────────────────────────────────

  Widget _labSnapCard(List<Map> labs) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDeco(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Lab Snapshot', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 12),
      ...labs.asMap().entries.map((e) {
        final i    = e.key;
        final lab  = e.value;
        final flag = lab['flag'] as String? ?? '';
        final c    = flag == 'danger'  ? const Color(0xFFef4444)
                   : flag == 'warning' ? const Color(0xFFf59e0b)
                   : const Color(0xFF22c55e);
        return Column(children: [
          if (i > 0) const Divider(height: 1, color: Color(0xFFf1f5f9)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Container(width: 4, height: 36,
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lab['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('Ref: ${lab['ref']}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${lab['value']} ${lab['unit']}',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: c)),
                if (flag == 'danger')
                  const Text('CRITICAL', style: TextStyle(fontSize: 9, color: Color(0xFFef4444), fontWeight: FontWeight.w700))
                else if (flag == 'warning')
                  const Text('Abnormal', style: TextStyle(fontSize: 9, color: Color(0xFFf59e0b), fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        ]);
      }),
    ]),
  );

  // ── Lab trends ───────────────────────────────────────────────────────────────

  Widget _labTrendsCard(Map<String, dynamic> labs) {
    const colors = [Color(0xFF0ea5e9), Color(0xFF22c55e), Color(0xFF6366f1), Color(0xFFf59e0b)];
    final entries = labs.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Lab Trends', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 14),
        ...entries.asMap().entries.map((e) {
          final i    = e.key;
          final name = e.value.key;
          final pts  = (e.value.value as List? ?? []);
          final c    = colors[i % colors.length];
          final spots = pts.asMap().entries.map((p) {
            final row = p.value as List;
            return FlSpot((row[0] as num).toDouble(), (row[1] as num).toDouble());
          }).toList();
          if (spots.length < 2) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
              const SizedBox(height: 6),
              SizedBox(
                height: 70,
                child: LineChart(LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [LineChartBarData(
                    spots: spots, isCurved: true,
                    color: c, barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3, color: c, strokeWidth: 1.5, strokeColor: Colors.white),
                    ),
                    belowBarData: BarAreaData(show: true, color: c.withValues(alpha: 0.08)),
                  )],
                )),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Event timeline ────────────────────────────────────────────────────────────

  Widget _eventsCard(List<Map> events) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDeco(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Clinical Events', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 12),
      ...events.asMap().entries.map((e) {
        final ev  = e.value;
        final src = ev['source'] as String? ?? '';
        final c   = src == 'LAB'    ? const Color(0xFF0ea5e9)
                  : src == 'INPUT'  ? const Color(0xFF22c55e)
                  : src == 'OUTPUT' ? const Color(0xFFf59e0b)
                  : const Color(0xFF6366f1);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(
                  src == 'LAB' ? '🧪' : src == 'INPUT' ? '💉' : src == 'OUTPUT' ? '💧' : '📊',
                  style: const TextStyle(fontSize: 14),
                )),
              ),
              if (e.key < events.length - 1)
                Container(width: 1, height: 18, color: const Color(0xFFe2e8f0)),
            ]),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(ev['label'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Text(ev['delta'] ?? '',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
              ]),
              Text(ev['value'] ?? '',
                  style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
            ])),
          ]),
        );
      }),
    ]),
  );

  // ── Helpers ──────────────────────────────────────────────────────────────────

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white, borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFe2e8f0)),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8, offset: const Offset(0, 2))],
  );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}
