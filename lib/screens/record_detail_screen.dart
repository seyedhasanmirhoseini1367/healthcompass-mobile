import 'package:flutter/material.dart';
import '../core/api_service.dart';

class RecordDetailScreen extends StatefulWidget {
  final String recordId;
  const RecordDetailScreen({super.key, required this.recordId});
  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  Map<String, dynamic>? _record;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.recordDetail(widget.recordId);
      setState(() { _record = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: Text(_record?['title'] ?? 'Record Detail',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _record == null
              ? const Center(child: Text('Record not found.',
                  style: TextStyle(color: Color(0xFF64748b))))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _headerCard(),
                    const SizedBox(height: 14),
                    if ((_record!['notes'] ?? '').toString().isNotEmpty) ...[
                      _section('Notes', _record!['notes']),
                      const SizedBox(height: 14),
                    ],
                    if (_record!['parsed_data'] != null &&
                        (_record!['parsed_data'] as Map).isNotEmpty) ...[
                      _parsedDataSection(),
                    ],
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
        Expanded(child: Text(_record!['title'] ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1e293b)))),
        if (_record!['is_flagged'] == true)
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
      _metaRow(Icons.category_outlined, 'Type',  _record!['record_type_display'] ?? ''),
      _metaRow(Icons.calendar_today_outlined, 'Date',
          _record!['record_date'] ?? _record!['uploaded_at']?.toString().split('T').first ?? ''),
    ]),
  );

  Widget _metaRow(IconData icon, String label, String value) =>
    Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF94a3b8)),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(color: Color(0xFF64748b), fontSize: 13)),
      Text(value,      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1e293b))),
    ]));

  Widget _section(String title, String content) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF64748b))),
      const SizedBox(height: 8),
      Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF1e293b), height: 1.6)),
    ]),
  );

  Widget _parsedDataSection() {
    final data = _record!['parsed_data'] as Map<String, dynamic>;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Parsed Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF64748b))),
        const SizedBox(height: 10),
        ...data.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 2, child: Text(e.key,
                style: const TextStyle(color: Color(0xFF64748b), fontSize: 13))),
            Expanded(flex: 3, child: Text(e.value.toString(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ]),
        )),
      ]),
    );
  }
}
