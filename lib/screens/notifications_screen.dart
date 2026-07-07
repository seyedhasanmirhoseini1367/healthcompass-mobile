import 'package:flutter/material.dart';
import '../core/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.notifications();
      setState(() { _items = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    final unread = _items.where((n) => n['is_read'] == false).toList();
    for (final n in unread) {
      await ApiService.markNotificationRead(n['id'].toString());
    }
    setState(() {
      for (final n in _items) {
        n['is_read'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((n) => n['is_read'] == false).length;
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Color(0xFF0ea5e9))),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _items.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_off_outlined, size: 56, color: Color(0xFFcbd5e1)),
                  SizedBox(height: 12),
                  Text('No notifications', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 16)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(_items[i]),
                  ),
                ),
    );
  }

  Widget _card(dynamic item) {
    final isRead  = item['is_read'] == true;
    final type    = item['type'] ?? 'system';

    final iconMap = {
      'health_alert':  Icons.warning_amber_rounded,
      'record_parsed': Icons.check_circle_outline_rounded,
      'model_result':  Icons.psychology_rounded,
      'system':        Icons.info_outline_rounded,
    };
    final colorMap = {
      'health_alert':  const Color(0xFFef4444),
      'record_parsed': const Color(0xFF22c55e),
      'model_result':  const Color(0xFF6366f1),
      'system':        const Color(0xFF0ea5e9),
    };

    final icon  = iconMap[type] ?? Icons.notifications_outlined;
    final color = colorMap[type] ?? const Color(0xFF64748b);

    return Opacity(
      opacity: isRead ? 0.55 : 1.0,
      child: InkWell(
        onTap: isRead ? null : () async {
          await ApiService.markNotificationRead(item['id'].toString());
          setState(() => item['is_read'] = true);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? const Color(0xFFf8fafc) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? const Color(0xFFe2e8f0) : color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(item['title'] ?? '',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF1e293b),
                    ))),
                if (!isRead)
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 4),
              Text(item['message'] ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748b), fontSize: 12, height: 1.4)),
              const SizedBox(height: 6),
              Text(_timeAgo(item['created_at']),
                  style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 11)),
            ])),
          ]),
        ),
      ),
    );
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
}
