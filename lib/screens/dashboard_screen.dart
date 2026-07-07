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
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: (_data?['unread_alerts'] ?? 0) > 0,
              label: Text('${_data?['unread_alerts'] ?? ''}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
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
                      _quickActions(),
                      const SizedBox(height: 20),
                      if ((_data!['recent_alerts'] as List? ?? []).isNotEmpty) ...[
                        _sectionHeader('Health Alerts', Icons.warning_amber_rounded, const Color(0xFFf59e0b),
                            onMore: () => context.push('/notifications')),
                        const SizedBox(height: 10),
                        _recentAlerts(),
                        const SizedBox(height: 20),
                      ],
                      if ((_data!['recent_predictions'] as List? ?? []).isNotEmpty) ...[
                        _sectionHeader('Recent AI Predictions', Icons.psychology_rounded, const Color(0xFF6366f1),
                            onMore: () => context.push('/predictions')),
                        const SizedBox(height: 10),
                        _recentPredictions(),
                        const SizedBox(height: 20),
                      ],
                      _sectionHeader('Records by Type', Icons.folder_rounded, const Color(0xFF0ea5e9)),
                      const SizedBox(height: 10),
                      _byTypeList(),
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
    final risk = _data?['latest_risk'];
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
          if (risk != null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Latest AI risk score: $risk%',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            )
          else
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
    final total    = _data?['total_records'] ?? 0;
    final flagged  = _data?['flagged_count'] ?? 0;
    final alerts   = _data?['unread_alerts'] ?? 0;
    return Row(children: [
      Expanded(child: _statCard('Records', '$total', Icons.folder_special_rounded, const Color(0xFF0ea5e9),
          onTap: () => context.go('/records'))),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Flagged', '$flagged', Icons.flag_rounded,
          flagged > 0 ? const Color(0xFFef4444) : const Color(0xFF22c55e),
          onTap: () => context.go('/records'))),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Alerts', '$alerts', Icons.warning_amber_rounded,
          alerts > 0 ? const Color(0xFFf59e0b) : const Color(0xFF64748b),
          onTap: () => context.push('/notifications'))),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFe2e8f0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748b))),
        ]),
      ),
    );

  Widget _quickActions() => Row(children: [
    Expanded(child: _actionCard(Icons.upload_file_rounded, 'Upload Record', const Color(0xFF0ea5e9),
        () async {
          final ok = await context.push<bool>('/upload');
          if (ok == true) _load();
        })),
    const SizedBox(width: 12),
    Expanded(child: _actionCard(Icons.smart_toy_rounded, 'AI Assistant', const Color(0xFF6366f1),
        () => context.go('/assistant'))),
    const SizedBox(width: 12),
    Expanded(child: _actionCard(Icons.bar_chart_rounded, 'Analytics', const Color(0xFF22c55e),
        () => context.go('/analytics'))),
  ]);

  Widget _actionCard(IconData icon, String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );

  Widget _sectionHeader(String title, IconData icon, Color color, {VoidCallback? onMore}) =>
    Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1e293b)))),
      if (onMore != null)
        TextButton(
          onPressed: onMore,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minimumSize: Size.zero,
          ),
          child: const Text('See all', style: TextStyle(fontSize: 12, color: Color(0xFF0ea5e9))),
        ),
    ]);

  Widget _recentAlerts() {
    final alerts = (_data!['recent_alerts'] as List).take(3).toList();
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: Column(children: alerts.asMap().entries.map((e) {
        final i = e.key;
        final a = e.value as Map;
        final sev = a['severity'] ?? 'info';
        final color = sev == 'critical' ? const Color(0xFFef4444)
            : sev == 'warning' ? const Color(0xFFf59e0b)
            : const Color(0xFF0ea5e9);
        final icon = sev == 'critical' ? Icons.error_rounded
            : sev == 'warning' ? Icons.warning_rounded
            : Icons.info_rounded;
        return Column(children: [
          if (i > 0) const Divider(height: 1, indent: 16),
          ListTile(
            dense: true,
            leading: Container(width: 34, height: 34,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 17)),
            title: Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text(a['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11)),
            trailing: Container(width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
        ]);
      }).toList()),
    );
  }

  Widget _recentPredictions() {
    final preds = (_data!['recent_predictions'] as List).take(3).toList();
    return Column(children: preds.map((p) {
      final risk  = (p['risk_pct'] as num?)?.toDouble();
      final model = p['model_name'] ?? 'AI Model';
      final label = p['result_label'] ?? '';
      final color = risk == null ? const Color(0xFF64748b)
          : risk >= 70 ? const Color(0xFFef4444)
          : risk >= 40 ? const Color(0xFFf59e0b)
          : const Color(0xFF22c55e);
      return GestureDetector(
        onTap: () => context.push('/predictions/${p['id']}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFe2e8f0))),
          child: Row(children: [
            Container(width: 40, height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.psychology_rounded, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(model, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              if (label.isNotEmpty)
                Text(label, style: const TextStyle(color: Color(0xFF64748b), fontSize: 12)),
            ])),
            if (risk != null)
              Text('${risk.toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color)),
            const Icon(Icons.chevron_right, color: Color(0xFFcbd5e1), size: 18),
          ]),
        ),
      );
    }).toList());
  }

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
              child: LinearProgressIndicator(value: pct,
                  backgroundColor: const Color(0xFFf1f5f9),
                  color: const Color(0xFF0ea5e9), minHeight: 6)),
          ]),
        );
      }).toList()),
    );
  }
}
