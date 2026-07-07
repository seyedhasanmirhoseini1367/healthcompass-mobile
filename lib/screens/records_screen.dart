import 'package:flutter/material.dart';
import '../core/api_service.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<dynamic> _records = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.records();
      setState(() { _records = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Medical Records', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : RefreshIndicator(
              onRefresh: _load,
              child: _records.isEmpty
                  ? const Center(child: Text('No records yet.', style: TextStyle(color: Color(0xFF64748b))))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _recordCard(_records[i]),
                    ),
            ),
    );
  }

  Widget _recordCard(Map record) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFe2e8f0)),
    ),
    child: Row(children: [
      Container(width: 4, height: 48, decoration: BoxDecoration(
        color: record['is_flagged'] == true ? const Color(0xFFef4444) : const Color(0xFF0ea5e9),
        borderRadius: BorderRadius.circular(4),
      )),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(record['title'] ?? 'Untitled',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 2),
        Text(record['record_type_display'] ?? '',
            style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
      ])),
      if (record['is_flagged'] == true)
        const Icon(Icons.flag, color: Color(0xFFef4444), size: 18),
    ]),
  );
}
