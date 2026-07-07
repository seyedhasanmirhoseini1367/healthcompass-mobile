import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<dynamic> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.records();
      setState(() { _records = data; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Could not load records.'; _loading = false; });
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
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFcbd5e1)),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFF64748b))),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load,
                      child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _records.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          Center(child: Column(children: [
                            Icon(Icons.folder_open_rounded, size: 56, color: Color(0xFFcbd5e1)),
                            SizedBox(height: 12),
                            Text('No records yet', style: TextStyle(color: Color(0xFF64748b), fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Records you upload on the website\nwill appear here',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 13)),
                          ])),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _recordCard(_records[i]),
                        ),
                ),
    );
  }

  Widget _recordCard(Map record) => InkWell(
    onTap: () => context.push('/records/${record['id']}'),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Row(children: [
        Container(width: 4, height: 52,
            decoration: BoxDecoration(
              color: record['is_flagged'] == true
                  ? const Color(0xFFef4444) : const Color(0xFF0ea5e9),
              borderRadius: BorderRadius.circular(4),
            )),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(record['title'] ?? 'Untitled',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1e293b))),
          const SizedBox(height: 3),
          Text(record['record_type_display'] ?? '',
              style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
          if ((record['record_date'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(record['record_date'].toString(),
                style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 11)),
          ],
        ])),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (record['is_flagged'] == true)
            const Icon(Icons.flag_rounded, color: Color(0xFFef4444), size: 16),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFFcbd5e1), size: 20),
        ]),
      ]),
    ),
  );
}
