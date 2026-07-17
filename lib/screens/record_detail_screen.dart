import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';
import '../core/error_handler.dart';
import '../models/medical_record.dart';
import '../widgets/error_retry_widget.dart';

class RecordDetailScreen extends StatefulWidget {
  final String recordId;
  const RecordDetailScreen({super.key, required this.recordId});
  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  MedicalRecord? _record;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.recordDetail(widget.recordId);
      setState(() { _record = data; _loading = false; });
    } catch (e) {
      setState(() { _error = friendlyError(e); _loading = false; });
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This record will be permanently deleted. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748b)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFef4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await ApiService.deleteRecord(widget.recordId);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) showErrorSnackBar(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: Text(_record?.title ?? 'Record Detail',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
        actions: [
          if (_record != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFef4444)),
              tooltip: 'Delete record',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _error != null
              ? ErrorRetryWidget(message: _error!, onRetry: _load)
              : _record == null
              ? const Center(child: Text('Record not found.',
                  style: TextStyle(color: Color(0xFF64748b))))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _headerCard(),
                    const SizedBox(height: 14),
                    if (_record!.notes.isNotEmpty) ...[
                      _textSection('Notes', _record!.notes),
                      const SizedBox(height: 14),
                    ],
                    if (_record!.labValues.isNotEmpty) ...[
                      _labValuesSection(),
                      const SizedBox(height: 14),
                    ],
                    if (_record!.wearablePoints.isNotEmpty) ...[
                      _wearableSection(),
                      const SizedBox(height: 14),
                    ],
                    if (_record!.parsedData.isNotEmpty) ...[
                      _parsedDataSection(),
                      const SizedBox(height: 14),
                    ],
                    if ((_record!.rawText ?? '').isNotEmpty) ...[
                      _textSection('Extracted Text', _record!.rawText!),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _headerCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFe2e8f0)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(_record!.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1e293b)))),
        if (_record!.isFlagged)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.flag_rounded, color: Color(0xFFef4444), size: 14),
              SizedBox(width: 4),
              Text('Flagged', style: TextStyle(color: Color(0xFFef4444), fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
      ]),
      const SizedBox(height: 12),
      _metaRow(Icons.category_outlined, 'Type',  _record!.recordTypeDisplay),
      _metaRow(Icons.calendar_today_outlined, 'Date',
          _record!.recordDate ?? _record!.uploadedAt?.split('T').first ?? ''),
      _metaRow(Icons.cloud_upload_outlined, 'Uploaded',
          _record!.uploadedAt?.split('T').first ?? ''),
    ]),
  );

  Widget _metaRow(IconData icon, String label, String value) =>
    Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF94a3b8)),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(color: Color(0xFF64748b), fontSize: 13)),
      Expanded(child: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1e293b)))),
    ]));

  // ── Lab Values ──────────────────────────────────────────────────────────────
  Widget _labValuesSection() {
    final labs = _record!.labValues;
    final abnormal  = labs.where((l) => l.isAbnormal).toList();
    final critical  = labs.where((l) => l.isCritical).toList();
    final normal    = labs.where((l) => !l.isAbnormal).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.science_rounded, size: 18, color: Color(0xFF0ea5e9)),
          const SizedBox(width: 8),
          const Text('Lab Values', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1e293b))),
          const Spacer(),
          if (critical.isNotEmpty)
            _badge('${critical.length} Critical', const Color(0xFFef4444)),
          if (abnormal.isNotEmpty) ...[
            const SizedBox(width: 6),
            _badge('${abnormal.length} Abnormal', const Color(0xFFf59e0b)),
          ],
        ]),
        const SizedBox(height: 12),
        // Critical first, then abnormal, then normal
        ...[ ...critical, ...abnormal.where((l) => !l.isCritical), ...normal ]
            .map((lab) => _labRow(lab)),
      ]),
    );
  }

  Widget _labRow(ParsedLabValue lab) {
    final isCritical = lab.isCritical;
    final isAbnormal = lab.isAbnormal;
    final color = isCritical ? const Color(0xFFef4444)
        : isAbnormal ? const Color(0xFFf59e0b)
        : const Color(0xFF22c55e);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isAbnormal ? 0.3 : 0.1)),
      ),
      child: Row(children: [
        Container(width: 3, height: 36,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lab.parameterName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1e293b))),
          if ((lab.referenceRange ?? '').isNotEmpty)
            Text('Ref: ${lab.referenceRange}',
                style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${lab.value} ${lab.unit ?? ''}',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
          if (isCritical)
            const Text('CRITICAL', style: TextStyle(color: Color(0xFFef4444), fontSize: 10, fontWeight: FontWeight.w900))
          else if (isAbnormal)
            const Text('Abnormal', style: TextStyle(color: Color(0xFFf59e0b), fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  // ── Wearable Points ─────────────────────────────────────────────────────────
  Widget _wearableSection() {
    final points = _record!.wearablePoints;

    // Group by metric
    final Map<String, List<WearableDataPoint>> grouped = {};
    for (final p in points) {
      final key = (p.metricDisplay?.isNotEmpty ?? false) ? p.metricDisplay! : (p.metric.isNotEmpty ? p.metric : 'Other');
      grouped.putIfAbsent(key, () => []).add(p);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.watch_rounded, size: 18, color: Color(0xFF6366f1)),
          const SizedBox(width: 8),
          const Text('Wearable Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1e293b))),
          const Spacer(),
          Text('${points.length} readings', style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        ...grouped.entries.map((e) {
          final vals = e.value.map((p) => p.value ?? 0.0).toList();
          final avg  = vals.reduce((a, b) => a + b) / vals.length;
          final min  = vals.reduce((a, b) => a < b ? a : b);
          final max  = vals.reduce((a, b) => a > b ? a : b);
          final unit = e.value.first.unit ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFf8fafc), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1e293b))),
              const SizedBox(height: 8),
              Row(children: [
                _statBox('Avg', avg.toStringAsFixed(1), unit, const Color(0xFF6366f1)),
                const SizedBox(width: 8),
                _statBox('Min', min.toStringAsFixed(1), unit, const Color(0xFF22c55e)),
                const SizedBox(width: 8),
                _statBox('Max', max.toStringAsFixed(1), unit, const Color(0xFFef4444)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _statBox(String label, String value, String unit, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        if (unit.isNotEmpty)
          Text(unit, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
      ]),
    ),
  );

  // ── Parsed Data ─────────────────────────────────────────────────────────────
  Widget _parsedDataSection() {
    final data = _record!.parsedData;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.data_object_rounded, size: 18, color: Color(0xFF94a3b8)),
          SizedBox(width: 8),
          Text('Parsed Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1e293b))),
        ]),
        const SizedBox(height: 10),
        ...data.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 2, child: Text(e.key,
                style: const TextStyle(color: Color(0xFF64748b), fontSize: 13))),
            Expanded(flex: 3, child: Text(e.value.toString(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1e293b)))),
          ]),
        )),
      ]),
    );
  }

  Widget _textSection(String title, String content) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF64748b))),
      const SizedBox(height: 8),
      Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF1e293b), height: 1.6)),
    ]),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}
