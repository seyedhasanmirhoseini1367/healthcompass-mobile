import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.me();
      setState(() { _user = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748b)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFef4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ApiService.logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _avatarCard(),
                  const SizedBox(height: 20),
                  _infoCard(),
                  const SizedBox(height: 16),
                  _actionsCard(),
                  const SizedBox(height: 16),
                  _dangerCard(),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text('HealthCompass — Research Prototype',
                        style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 11)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _avatarCard() {
    final name   = _user?['full_name'] ?? _user?['username'] ?? 'User';
    final email  = _user?['email'] ?? '';
    final role   = _user?['role_display'] ?? 'Patient';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF6366f1)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          child: Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        Text(name,  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(role, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _infoCard() => _card('Account Info', [
    _infoRow(Icons.email_outlined,  'Email',    _user?['email']    ?? '—'),
    _infoRow(Icons.badge_outlined,  'Username', _user?['username'] ?? '—'),
    _infoRow(Icons.verified_user,   'Status',
        _user?['is_approved'] == true ? 'Approved' : 'Pending Approval',
        valueColor: _user?['is_approved'] == true ? const Color(0xFF22c55e) : const Color(0xFFf59e0b)),
  ]);

  Widget _actionsCard() => _card('Settings', [
    _actionRow(Icons.edit_outlined, 'Edit Profile', const Color(0xFF0ea5e9), () async {
      if (_user == null) return;
      final updated = await context.push<bool>('/edit-profile', extra: _user);
      if (updated == true) _load();
    }),
    _actionRow(Icons.lock_outline, 'Change Password', const Color(0xFF6366f1), () {
      context.push('/change-password');
    }),
    _actionRow(Icons.local_hospital_rounded, 'Emergency Card', const Color(0xFFef4444), () {
      context.push('/emergency-card');
    }),
    _actionRow(Icons.psychology_rounded, 'My AI Predictions', const Color(0xFF22c55e), () {
      context.push('/predictions');
    }),
    _actionRow(Icons.notifications_outlined, 'Notifications', const Color(0xFF94a3b8), () {
      context.push('/notifications');
    }),
  ]);

  Widget _dangerCard() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFe2e8f0)),
    ),
    child: ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.logout_rounded, color: Color(0xFFef4444), size: 20),
      ),
      title: const Text('Sign Out', style: TextStyle(color: Color(0xFFef4444), fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFcbd5e1)),
      onTap: _logout,
    ),
  );

  Widget _card(String title, List<Widget> items) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF64748b))),
      const SizedBox(height: 12),
      ...items,
    ]),
  );

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Icon(icon, size: 18, color: const Color(0xFF94a3b8)),
      const SizedBox(width: 10),
      Text('$label  ', style: const TextStyle(color: Color(0xFF64748b), fontSize: 13)),
      Expanded(child: Text(value, textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
              color: valueColor ?? const Color(0xFF1e293b)))),
    ]));

  Widget _actionRow(IconData icon, String label, Color color, VoidCallback onTap) =>
    InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 17, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        const Icon(Icons.chevron_right, color: Color(0xFFcbd5e1), size: 18),
      ]),
    ));
}
