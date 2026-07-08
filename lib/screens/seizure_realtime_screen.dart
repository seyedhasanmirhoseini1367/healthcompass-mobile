import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/api_service.dart';

class SeizureRealtimeScreen extends StatefulWidget {
  const SeizureRealtimeScreen({super.key});
  @override
  State<SeizureRealtimeScreen> createState() => _SeizureRealtimeScreenState();
}

class _SeizureRealtimeScreenState extends State<SeizureRealtimeScreen> {
  Map<String, dynamic>? _result;
  bool   _loading  = false;
  String? _error;
  String? _fileName;

  Future<void> _pickAndAnalyze() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['parquet', 'csv'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.bytes == null) return;

    setState(() { _loading = true; _error = null; _result = null; _fileName = file.name; });
    try {
      final res = await ApiService.seizureRealtimeAnalyze(file.bytes!, file.name);
      setState(() { _result = res; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Realtime EEG Analysis', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFFf59e0b),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(),
          const SizedBox(height: 16),
          _uploadCard(),
          if (_loading) ...[
            const SizedBox(height: 24),
            _loadingCard(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            _errorCard(),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _summaryCard(),
            const SizedBox(height: 14),
            _timelineChart(),
            const SizedBox(height: 14),
            _windowTable(),
          ],
        ],
      ),
    );
  }

  // ── Info card ─────────────────────────────────────────────────────────────────

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFfef3c7), Color(0xFFfde68a)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFfde68a)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('⚡', style: TextStyle(fontSize: 28)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Window-by-Window EEG Analysis',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF92400e))),
        SizedBox(height: 4),
        Text(
          'Upload a parquet or CSV EEG recording. The ensemble of 3 ONNX models '
          '(CNN-Transformer, LSTM+Attention, CNN-LSTM Fusion) will analyse every '
          '10-second window and produce a seizure probability timeline.',
          style: TextStyle(fontSize: 12, color: Color(0xFF92400e), height: 1.5),
        ),
      ])),
    ]),
  );

  // ── Upload card ──────────────────────────────────────────────────────────────

  Widget _uploadCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFe2e8f0)),
    ),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFfef3c7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: Text('📂', style: TextStyle(fontSize: 30))),
      ),
      const SizedBox(height: 14),
      Text(
        _fileName != null ? _fileName! : 'No file selected',
        style: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13,
          color: _fileName != null ? const Color(0xFF1e293b) : const Color(0xFF94a3b8),
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      const Text('Parquet or CSV · 19 EEG channels · 200 Hz',
          style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _pickAndAnalyze,
          icon: const Icon(Icons.upload_file_rounded),
          label: Text(_fileName == null ? 'Pick EEG File' : 'Pick Different File'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFf59e0b),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]),
  );

  // ── Loading card ─────────────────────────────────────────────────────────────

  Widget _loadingCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFe2e8f0)),
    ),
    child: Column(children: [
      const CircularProgressIndicator(color: Color(0xFFf59e0b)),
      const SizedBox(height: 16),
      const Text('Running ONNX ensemble…',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1e293b))),
      const SizedBox(height: 4),
      const Text('Analysing each 10-second window. This may take a moment.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
    ]),
  );

  // ── Error card ───────────────────────────────────────────────────────────────

  Widget _errorCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFfef2f2), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFfecaca)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: Color(0xFFef4444), size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(_error ?? '',
          style: const TextStyle(fontSize: 12, color: Color(0xFF991b1b)))),
    ]),
  );

  // ── Summary card ─────────────────────────────────────────────────────────────

  Widget _summaryCard() {
    final r         = _result!;
    final pct       = (r['seizure_pct'] as num).toDouble();
    final summary   = r['summary'] as String? ?? '';
    final color     = pct >= 30 ? const Color(0xFFef4444)
                    : pct >= 10 ? const Color(0xFFf59e0b)
                    : const Color(0xFF22c55e);
    final emoji     = pct >= 30 ? '🚨' : pct >= 10 ? '⚠️' : '✅';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(summary, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
            Text('${r['seizure_windows']} / ${r['total_windows']} windows flagged  ·  '
                '${r['duration_sec']}s total',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748b))),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${pct.toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: color)),
            const Text('Seizure', style: TextStyle(fontSize: 10, color: Color(0xFF94a3b8))),
          ]),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: const Color(0xFFf1f5f9),
            color: color, minHeight: 10,
          )),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: const Color(0xFFef4444), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('Seizure', style: TextStyle(fontSize: 10, color: Color(0xFF64748b))),
          ]),
          Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: const Color(0xFF22c55e), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('LPD / Normal', style: TextStyle(fontSize: 10, color: Color(0xFF64748b))),
          ]),
        ]),
      ]),
    );
  }

  // ── Timeline chart ───────────────────────────────────────────────────────────

  Widget _timelineChart() {
    final timeline = (_result!['timeline'] as List? ?? []).cast<Map>();
    if (timeline.isEmpty) return const SizedBox.shrink();

    final spots = timeline.asMap().entries.map((e) {
      final t = e.value;
      return FlSpot(
        (t['time_sec'] as num).toDouble(),
        (t['is_seizure'] == true ? (t['confidence'] as num).toDouble() : 0.0),
      );
    }).toList();

    final maxX = spots.last.x;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Seizure Probability Timeline',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 4),
        const Text('Confidence of each 10-s window flagged as seizure',
            style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
        const SizedBox(height: 14),
        SizedBox(
          height: 160,
          child: LineChart(LineChartData(
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFf1f5f9), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${(v * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF94a3b8))),
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 22,
                interval: maxX > 0 ? (maxX / 5).ceilToDouble() : 10,
                getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)}s',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF94a3b8))),
              )),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0, maxY: 1,
            lineBarsData: [
              LineChartBarData(
                spots: spots, isCurved: false,
                color: const Color(0xFFef4444), barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                    radius: s.y > 0 ? 4 : 2,
                    color: s.y > 0 ? const Color(0xFFef4444) : const Color(0xFF22c55e),
                    strokeWidth: 1.5, strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                    show: true, color: const Color(0xFFef4444).withValues(alpha: 0.08)),
              ),
            ],
          )),
        ),
      ]),
    );
  }

  // ── Window table ─────────────────────────────────────────────────────────────

  Widget _windowTable() {
    final timeline = (_result!['timeline'] as List? ?? []).cast<Map>();
    final flagged  = timeline.where((t) => t['is_seizure'] == true).toList();
    if (flagged.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFe2e8f0))),
        child: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF22c55e), size: 20),
          SizedBox(width: 10),
          Text('No windows flagged as seizure activity.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFe2e8f0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Flagged Windows (${flagged.length})',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 10),
        ...flagged.map((t) {
          final conf = ((t['confidence'] as num).toDouble() * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.warning_rounded, color: Color(0xFFef4444), size: 16),
              const SizedBox(width: 8),
              Text('T = ${t['time_sec']}s',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text(t['label'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748b))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(20)),
                child: Text('$conf%',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11,
                        color: Color(0xFFef4444))),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}
