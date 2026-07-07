import 'package:flutter/material.dart';
import '../core/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _error   = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final data = await ApiService.dashboard();
      setState(() { _data = data; _loading = false; });
    } catch (_) {
      setState(() { _error = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: Row(children: [
          Container(width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF6366f1)]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 10),
          const Text('HealthCompass', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _error
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFcbd5e1)),
                  const SizedBox(height: 12),
                  const Text('Could not connect', style: TextStyle(color: Color(0xFF64748b))),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _greeting(),
                      const SizedBox(height: 16),
                      _statsRow(),
                      const SizedBox(height: 20),
                      _sectionTitle('Records by Type'),
                      const SizedBox(height: 10),
                      _byTypeList(),
                      const SizedBox(height: 20),
                      _sectionTitle('Quick Tips'),
                      const SizedBox(height: 10),
                      _tips(),
                    ],
                  ),
                ),
    );
  }

  Widget _greeting() {
    final user = _data?['user'];
    final name = user?['full_name'] ?? user?['username'] ?? 'User';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF6366f1)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$greeting,', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(user?['role_display'] ?? 'Patient',
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ])),
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          )),
        ),
      ]),
    );
  }

  Widget _statsRow() {
    final total   = _data?['total_records'] ?? 0;
    final flagged = _data?['flagged_count'] ?? 0;
    return Row(children: [
      Expanded(child: _statCard('Total Records', '$total', Icons.folder_special_rounded, const Color(0xFF0ea5e9))),
      const SizedBox(width: 12),
      Expanded(child: _statCard('Flagged', '$flagged', Icons.flag_rounded,
          flagged > 0 ? const Color(0xFFef4444) : const Color(0xFF22c55e))),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Row(children: [
      Container(width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748b))),
      ]),
    ]),
  );

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1e293b)));

  Widget _byTypeList() {
    final byType = _data?['records_by_type'] as Map? ?? {};
    if (byType.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFe2e8f0))),
        child: const Center(child: Text('No records uploaded yet',
            style: TextStyle(color: Color(0xFF94a3b8)))),
      );
    }
    final total = byType.values.fold<int>(0, (s, v) => s + (v as int));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: Column(children: byType.entries.map((e) {
        final pct = total > 0 ? (e.value as int) / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${e.value}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748b))),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: const Color(0xFFf1f5f9),
                color: const Color(0xFF0ea5e9),
                minHeight: 6,
              ),
            ),
          ]),
        );
      }).toList()),
    );
  }

  Widget _tips() => Column(children: const [
    _TipCard(icon: Icons.smart_toy_rounded, color: Color(0xFF6366f1),
        text: 'Ask the AI Assistant about your health records for instant insights.'),
    SizedBox(height: 10),
    _TipCard(icon: Icons.upload_file_rounded, color: Color(0xFF22c55e),
        text: 'Upload lab results and medical notes on the website for analysis.'),
    SizedBox(height: 10),
    _TipCard(icon: Icons.security_rounded, color: Color(0xFF0ea5e9),
        text: 'Your data is encrypted and only accessible by you.'),
  ]);
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   text;
  const _TipCard({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5))),
    ]),
  );
}
