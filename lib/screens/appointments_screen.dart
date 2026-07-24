import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';
import '../core/error_handler.dart';
import '../core/notification_service.dart';
import '../models/appointment.dart';
import '../widgets/error_retry_widget.dart';
import '../widgets/skeleton_loader.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Appointment> _upcoming = [];
  List<Appointment> _past = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final up   = await ApiService.appointments(show: 'upcoming');
      final past = await ApiService.appointments(show: 'past');
      setState(() { _upcoming = up; _past = past; _loading = false; });
      for (final appt in up) {
        NotificationService.scheduleAppointmentReminders(appt);
      }
    } catch (e) {
      setState(() { _error = friendlyError(e); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        title: const Text('Appointments', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () async {
          final created = await context.push<bool>('/appointments/create');
          if (created == true) _load();
        },
      ),
      body: _loading
          ? const SkeletonListPlaceholder()
          : _error != null
              ? ErrorRetryWidget(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _AppointmentList(
                      appointments: _upcoming,
                      empty: 'No upcoming appointments.\nTap + to schedule one.',
                      onRefresh: _load,
                      onEdit: (a) async {
                        final ok = await context.push<bool>('/appointments/${a.id}/edit', extra: a);
                        if (ok == true) _load();
                      },
                      onDelete: (a) => _confirmDelete(a),
                    ),
                    _AppointmentList(
                      appointments: _past,
                      empty: 'No past appointments.',
                      isPast: true,
                      onRefresh: _load,
                      onEdit: (_) {},
                      onDelete: (a) => _confirmDelete(a),
                    ),
                  ],
                ),
    );
  }

  Future<void> _confirmDelete(Appointment appt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Appointment?'),
        content: Text('Delete "${appt.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.deleteAppointment(appt.id);
        await NotificationService.cancelAppointmentReminders(appt.id);
        _load();
      } catch (e) {
        if (mounted) showErrorSnackBar(context, friendlyError(e));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AppointmentList extends StatelessWidget {
  final List<Appointment> appointments;
  final String empty;
  final bool isPast;
  final VoidCallback onRefresh;
  final void Function(Appointment) onEdit;
  final void Function(Appointment) onDelete;

  const _AppointmentList({
    required this.appointments,
    required this.empty,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          children: [
            SizedBox(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(empty,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                    if (!isPast) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => context.push<bool>('/appointments/create').then((ok) {
                          if (ok == true) onRefresh();
                        }),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Schedule an appointment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: appointments.length,
        itemBuilder: (_, i) => _AppointmentCard(
          appt: appointments[i],
          isPast: isPast,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appt;
  final bool isPast;
  final void Function(Appointment) onEdit;
  final void Function(Appointment) onDelete;

  const _AppointmentCard({
    required this.appt, required this.isPast,
    required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(appt.appointmentDatetime) ?? DateTime.now();
    final monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    final reminders = <String>[];
    if (appt.remind24h) reminders.add('24h');
    if (appt.remind3h)  reminders.add('3h');
    if (appt.remind2h)  reminders.add('2h');
    if (appt.remind1h)  reminders.add('1h');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPast ? Colors.white.withValues(alpha: 0.75) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date box
            Container(
              width: 52, height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFE0F2FE), Color(0xFFEDE9FE)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${dt.day}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                  Text(monthNames[dt.month - 1],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appt.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10, runSpacing: 2,
                    children: [
                      _meta(Icons.access_time_outlined,
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'),
                      if (appt.doctorName.isNotEmpty)
                        _meta(Icons.person_outline, appt.doctorName),
                      if (appt.location.isNotEmpty)
                        _meta(Icons.location_on_outlined, appt.location),
                    ],
                  ),
                  if (reminders.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: reminders.map((r) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_outlined, size: 10, color: Color(0xFF1D4ED8)),
                            const SizedBox(width: 3),
                            Text(r, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            if (!isPast)
              Column(
                children: [
                  GestureDetector(
                    onTap: () => onEdit(appt),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => onDelete(appt),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: () => onDelete(appt),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF94A3B8)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: const Color(0xFF64748B)),
      const SizedBox(width: 3),
      Flexible(child: Text(text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          overflow: TextOverflow.ellipsis)),
    ],
  );
}
