import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.dashboard();
      setState(() { _data = data; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('HealthCompass', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _greeting(),
                  const SizedBox(height: 16),
                  _statsRow(),
                  const SizedBox(height: 20),
                  _menuGrid(context),
                ],
              ),
            ),
    );
  }

  Widget _greeting() {
    final user = _data?['user'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF6366f1)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hello, ${user?['username'] ?? 'User'} 👋',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(user?['role'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]),
    );
  }

  Widget _statsRow() {
    final total   = _data?['total_records'] ?? 0;
    final flagged = _data?['flagged_count'] ?? 0;
    return Row(children: [
      Expanded(child: _statCard('Records', '$total', Icons.folder_special, const Color(0xFF0ea5e9))),
      const SizedBox(width: 12),
      Expanded(child: _statCard('Flagged', '$flagged', Icons.flag, const Color(0xFFef4444))),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Row(children: [
      Icon(icon, color: color, size: 28),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748b))),
      ]),
    ]),
  );

  Widget _menuGrid(BuildContext context) => GridView.count(
    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
    children: [
      _menuCard(context, 'My Records',  Icons.file_copy,    const Color(0xFF0ea5e9), '/records'),
      _menuCard(context, 'AI Assistant', Icons.smart_toy,   const Color(0xFF6366f1), '/assistant'),
      _menuCard(context, 'AI Insights', Icons.insights,     const Color(0xFF22c55e), '/insights'),
      _menuCard(context, 'Profile',     Icons.person,       const Color(0xFFf59e0b), '/profile'),
    ],
  );

  Widget _menuCard(BuildContext context, String label, IconData icon, Color color, String route) =>
    InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFe2e8f0))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
}
