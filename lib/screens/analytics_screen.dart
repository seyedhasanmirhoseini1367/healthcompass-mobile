import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _error   = false;
  String? _selectedBiomarker;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final data = await ApiService.analytics();
      setState(() {
        _data = data;
        _loading = false;
        final trends = data['biomarker_trends'] as Map? ?? {};
        if (_selectedBiomarker == null || !trends.containsKey(_selectedBiomarker)) {
          _selectedBiomarker = trends.isNotEmpty ? trends.keys.first : null;
        }
      });
    } catch (_) {
      setState(() { _error = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
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
    const Text('Could not load analytics', style: TextStyle(color: Color(0xFF64748b))),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: _load, child: const Text('Retry')),
  ]));

  Widget _buildContent() {
    final d      = _data!;
    final hasData = (d['total_records'] ?? 0) > 0;

    return CustomScrollView(
      slivers: [
        // ── Gradient header ──────────────────────────────────────────────────
        SliverToBoxAdapter(child: _GradientHeader()),

        // ── Hub cards ────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(children: [
              _HubCard(
                number: '1',
                numberColor: const Color(0xFF6366f1),
                icon: '🩺',
                title: 'My Health',
                description: 'Your personal biomarker trends, latest lab values, health alerts, and AI risk score — all in one place.',
                tags: const [
                  _Tag('Trend Analysis', Color(0xFFede9fe), Color(0xFF6d28d9)),
                  _Tag('Lab Values',     Color(0xFFdcfce7), Color(0xFF15803d)),
                  _Tag('AI Alerts',      Color(0xFFfef3c7), Color(0xFFb45309)),
                ],
                actionLabel: 'View below ↓',
                actionColor: const Color(0xFF6366f1),
                onTap: null, // scrolls naturally
              ),
              const SizedBox(height: 12),
              _HubCard(
                number: '2',
                numberColor: const Color(0xFF0ea5e9),
                icon: '🌍',
                title: 'Population Insights',
                description: 'Anonymised aggregate statistics across all users — query patterns, safety interventions, and knowledge base coverage.',
                tags: const [
                  _Tag('Anonymised',  Color(0xFFdbeafe), Color(0xFF1d4ed8)),
                  _Tag('Usage Stats', Color(0xFFf0fdf4), Color(0xFF166534)),
                  _Tag('Safety',      Color(0xFFfef9c3), Color(0xFF854d0e)),
                ],
                actionLabel: 'Open →',
                actionColor: const Color(0xFF0ea5e9),
                onTap: () => context.push('/population-insights'),
              ),
              const SizedBox(height: 12),
              _HubCard(
                number: '3',
                numberColor: const Color(0xFF22c55e),
                icon: '🤖',
                title: 'AI Models',
                description: 'Browse and run specialist AI models — from EEG seizure analysis to cardiovascular risk prediction.',
                tags: const [
                  _Tag('EEG',      Color(0xFFfce7f3), Color(0xFF9d174d)),
                  _Tag('Cardio',   Color(0xFFffe4e6), Color(0xFF9f1239)),
                  _Tag('Diabetes', Color(0xFFf0fdf4), Color(0xFF166534)),
                ],
                actionLabel: 'Browse →',
                actionColor: const Color(0xFF22c55e),
                onTap: () => context.push('/ai-models'),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),

        // ── Divider + My Health label ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('🩺', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 6),
                  Text('My Health', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Divider(color: Color(0xFFe2e8f0))),
            ]),
          ),
        ),

        // ── Stats row ────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          sliver: SliverToBoxAdapter(child: _statsRow()),
        ),

        // ── Health data ──────────────────────────────────────────────────────
        if (!hasData)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverToBoxAdapter(child: _emptyState()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(delegate: SliverChildListDelegate([
              if ((_data!['biomarker_trends'] as Map? ?? {}).isNotEmpty) ...[
                _sectionTitle('Biomarker Trends', Icons.show_chart_rounded, const Color(0xFF0ea5e9)),
                const SizedBox(height: 10),
                _trendChart(),
                const SizedBox(height: 20),
              ],
              if ((_data!['biomarker_latest'] as Map? ?? {}).isNotEmpty) ...[
                _sectionTitle('Latest Lab Values', Icons.science_outlined, const Color(0xFF22c55e)),
                const SizedBox(height: 10),
                _labValues(),
                const SizedBox(height: 20),
              ],
              if ((_data!['alerts'] as List? ?? []).isNotEmpty) ...[
                _sectionTitle('Health Alerts', Icons.warning_amber_rounded, const Color(0xFFf59e0b)),
                const SizedBox(height: 10),
                _alertsList(),
                const SizedBox(height: 20),
              ],
              if ((_data!['predictions'] as List? ?? []).isNotEmpty) ...[
                _sectionTitle('AI Risk Predictions', Icons.psychology_rounded, const Color(0xFF6366f1)),
                const SizedBox(height: 10),
                _predictionsList(),
                const SizedBox(height: 20),
              ],
              if ((_data!['records_by_type'] as Map? ?? {}).isNotEmpty) ...[
                _sectionTitle('Records by Type', Icons.folder_outlined, const Color(0xFF64748b)),
                const SizedBox(height: 10),
                _recordsByType(),
              ],
            ])),
          ),
      ],
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _statsRow() {
    final d    = _data!;
    final risk = d['latest_risk'];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard('Records',    '${d['total_records'] ?? 0}',    Icons.folder_special_rounded, const Color(0xFF0ea5e9)),
        _statCard('Biomarkers', '${d['total_biomarkers'] ?? 0}', Icons.science_rounded,        const Color(0xFF22c55e)),
        _statCard('Alerts', '${d['unread_alerts'] ?? 0}',
            Icons.warning_amber_rounded,
            (d['unread_alerts'] ?? 0) > 0 ? const Color(0xFFef4444) : const Color(0xFF64748b)),
        _statCard('Latest Risk',
            risk != null ? '$risk%' : '—',
            Icons.analytics_rounded,
            risk == null ? const Color(0xFF64748b)
                : risk >= 70 ? const Color(0xFFef4444)
                : risk >= 40 ? const Color(0xFFf59e0b)
                : const Color(0xFF22c55e)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 18),
      ),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748b))),
    ]),
  );

  Widget _sectionTitle(String title, IconData icon, Color color) => Row(children: [
    Icon(icon, size: 18, color: color),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1e293b))),
  ]);

  // ── Biomarker Trend Chart ─────────────────────────────────────────────────

  Widget _trendChart() {
    final trends = (_data!['biomarker_trends'] as Map? ?? {});
    final names  = trends.keys.toList();

    final points = (trends[_selectedBiomarker] as List? ?? [])
        .asMap().entries
        .map((e) {
          final pt = e.value as Map;
          return FlSpot(e.key.toDouble(), (pt['value'] as num).toDouble());
        }).toList();

    final dates = (trends[_selectedBiomarker] as List? ?? [])
        .map((p) => (p as Map)['date']?.toString() ?? '').toList();

    final unit = points.isNotEmpty
        ? ((trends[_selectedBiomarker] as List).last as Map)['unit'] ?? '' : '';

    final minY = points.isEmpty ? 0.0 : points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = points.isEmpty ? 1.0 : points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final pad  = (maxY - minY) * 0.2;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFe2e8f0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: names.map((name) {
                final selected = name == _selectedBiomarker;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBiomarker = name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF0ea5e9) : const Color(0xFFf1f5f9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(name, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : const Color(0xFF475569),
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (points.length >= 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
            child: SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFf1f5f9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 28,
                    interval: dates.length <= 4 ? 1 : (dates.length / 4).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= dates.length) return const SizedBox.shrink();
                      final d = dates[i];
                      final label = d.length >= 7 ? d.substring(5) : d;
                      return Padding(padding: const EdgeInsets.only(top: 6),
                          child: Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94a3b8))));
                    },
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 42,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 9, color: Color(0xFF94a3b8))),
                  )),
                  topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: (minY - pad).clamp(0, double.infinity),
                maxY: maxY + pad,
                lineBarsData: [
                  LineChartBarData(
                    spots: points, isCurved: true,
                    color: const Color(0xFF0ea5e9), barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3.5, color: const Color(0xFF0ea5e9),
                        strokeWidth: 1.5, strokeColor: Colors.white),
                    ),
                    belowBarData: BarAreaData(
                        show: true, color: const Color(0xFF0ea5e9).withValues(alpha: 0.08)),
                  ),
                ],
              )),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              points.length == 1
                  ? 'Only one data point — need at least 2 to show a trend.'
                  : 'No data for this biomarker.',
              style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
            ),
          ),
        if (unit.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Unit: $unit',
                style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 11)),
          ),
      ]),
    );
  }

  // ── Lab Values ────────────────────────────────────────────────────────────

  Widget _labValues() {
    final latest = _data!['biomarker_latest'] as Map? ?? {};
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: latest.entries.toList().asMap().entries.map((e) {
        final i    = e.key;
        final name = e.value.key as String;
        final v    = e.value.value as Map;
        final isAbnormal = v['abnormal'] == true;
        final isCritical = v['critical'] == true;
        final valueColor = isCritical ? const Color(0xFFef4444)
            : isAbnormal ? const Color(0xFFf59e0b) : const Color(0xFF22c55e);
        return Column(children: [
          if (i > 0) const Divider(height: 1, indent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if ((v['ref'] ?? '').toString().isNotEmpty)
                  Text('Ref: ${v['ref']}', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${v['value']} ${v['unit'] ?? ''}',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: valueColor)),
                if (isCritical)
                  const Text('CRITICAL', style: TextStyle(fontSize: 10, color: Color(0xFFef4444), fontWeight: FontWeight.w700))
                else if (isAbnormal)
                  const Text('Abnormal', style: TextStyle(fontSize: 10, color: Color(0xFFf59e0b), fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        ]);
      }).toList()),
    );
  }

  // ── Alerts ────────────────────────────────────────────────────────────────

  Widget _alertsList() {
    final alerts = (_data!['alerts'] as List? ?? []).take(5).toList();
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: alerts.asMap().entries.map((e) {
        final i     = e.key;
        final alert = e.value as Map;
        final sev   = alert['severity'] ?? 'info';
        final color = sev == 'critical' ? const Color(0xFFef4444)
            : sev == 'warning' ? const Color(0xFFf59e0b) : const Color(0xFF0ea5e9);
        final icon  = sev == 'critical' ? Icons.error_rounded
            : sev == 'warning' ? Icons.warning_rounded : Icons.info_rounded;
        return Column(children: [
          if (i > 0) const Divider(height: 1, indent: 16),
          ListTile(
            leading: Container(width: 36, height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18)),
            title: Text(alert['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text(alert['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
            trailing: alert['is_read'] == false
                ? Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
                : null,
            onTap: () async {
              if (alert['is_read'] == false) {
                await ApiService.markAlertRead(alert['id'].toString());
                setState(() => (alert as dynamic)['is_read'] = true);
              }
            },
          ),
        ]);
      }).toList()),
    );
  }

  // ── AI Predictions ────────────────────────────────────────────────────────

  Widget _predictionsList() {
    final preds = _data!['predictions'] as List? ?? [];
    return Column(children: preds.map((p) {
      final risk  = (p['risk_pct'] as num?)?.toDouble();
      final label = p['result_label'] ?? '';
      final model = p['model_name'] ?? 'AI Model';
      final color = risk == null ? const Color(0xFF64748b)
          : risk >= 70 ? const Color(0xFFef4444)
          : risk >= 40 ? const Color(0xFFf59e0b)
          : const Color(0xFF22c55e);
      return GestureDetector(
        onTap: () => context.push('/predictions/${p['id']}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFe2e8f0)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(model, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              if (risk != null)
                Text('${risk.toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
            ]),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
            ],
            if (risk != null) ...[
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: risk / 100,
                    backgroundColor: const Color(0xFFf1f5f9), color: color, minHeight: 6)),
            ],
          ]),
        ),
      );
    }).toList());
  }

  // ── Records by Type ───────────────────────────────────────────────────────

  Widget _recordsByType() {
    final byType = _data!['records_by_type'] as Map? ?? {};
    final total  = byType.values.fold<int>(0, (s, v) => s + (v as int));
    final colors = [
      const Color(0xFF0ea5e9), const Color(0xFF22c55e), const Color(0xFF6366f1),
      const Color(0xFFf59e0b), const Color(0xFFef4444), const Color(0xFF8b5cf6),
      const Color(0xFF14b8a6), const Color(0xFFf97316),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: byType.entries.toList().asMap().entries.map((e) {
        final i   = e.key;
        final pct = total > 0 ? (e.value.value as int) / total : 0.0;
        final col = colors[i % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(e.value.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${e.value.value}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748b))),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct,
                  backgroundColor: const Color(0xFFf1f5f9), color: col, minHeight: 6)),
          ]),
        );
      }).toList()),
    );
  }

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Column(children: [
      const Icon(Icons.bar_chart_rounded, size: 56, color: Color(0xFFcbd5e1)),
      const SizedBox(height: 16),
      const Text('No analytics yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF475569))),
      const SizedBox(height: 8),
      const Text('Upload medical records to see your health analytics here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94a3b8), fontSize: 13, height: 1.5)),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => context.go('/records'),
        icon: const Icon(Icons.upload_file_rounded, size: 18),
        label: const Text('Go to Records'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0ea5e9),
          side: const BorderSide(color: Color(0xFF0ea5e9)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ]),
  );
}

// ── Gradient header ───────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4f46e5), Color(0xFF6366f1), Color(0xFF0ea5e9)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(children: [
            // Decorative dots
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: i == 2 ? 0.6 : 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ))),
            const SizedBox(height: 16),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'AI & Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'Your personal health intelligence hub',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Hub card ──────────────────────────────────────────────────────────────────

class _Tag {
  final String text;
  final Color bg;
  final Color fg;
  const _Tag(this.text, this.bg, this.fg);
}

class _HubCard extends StatelessWidget {
  final String number;
  final Color  numberColor;
  final String icon;
  final String title;
  final String description;
  final List<_Tag> tags;
  final String actionLabel;
  final Color  actionColor;
  final VoidCallback? onTap;

  const _HubCard({
    required this.number,
    required this.numberColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.tags,
    required this.actionLabel,
    required this.actionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Top row: number badge + icon + title
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: numberColor, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 10),
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1e293b))),
            ),
          ]),
          const SizedBox(height: 10),
          // Description
          Text(description,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748b), height: 1.5)),
          const SizedBox(height: 12),
          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(999)),
              child: Text(t.text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.fg)),
            )).toList(),
          ),
          const SizedBox(height: 14),
          // Action link
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(actionLabel, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: actionColor)),
          ]),
        ]),
      ),
    );
  }
}
