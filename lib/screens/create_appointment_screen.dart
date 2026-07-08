import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateAppointmentScreen({super.key, this.existing});

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title   = TextEditingController();
  final _doctor  = TextEditingController();
  final _loc     = TextEditingController();
  final _notes   = TextEditingController();

  DateTime? _pickedDt;
  bool _r24h = true;
  bool _r3h  = false;
  bool _r2h  = false;
  bool _r1h  = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text  = e['title']       ?? '';
      _doctor.text = e['doctor_name'] ?? '';
      _loc.text    = e['location']    ?? '';
      _notes.text  = e['notes']       ?? '';
      _r24h = e['remind_24h'] ?? true;
      _r3h  = e['remind_3h']  ?? false;
      _r2h  = e['remind_2h']  ?? false;
      _r1h  = e['remind_1h']  ?? true;
      final raw = e['appointment_datetime'];
      if (raw != null) _pickedDt = DateTime.tryParse(raw)?.toLocal();
    }
  }

  @override
  void dispose() {
    _title.dispose(); _doctor.dispose(); _loc.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _pickedDt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _pickedDt != null
          ? TimeOfDay(hour: _pickedDt!.hour, minute: _pickedDt!.minute)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _pickedDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedDt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date and time.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'title':                _title.text.trim(),
        'doctor_name':          _doctor.text.trim(),
        'location':             _loc.text.trim(),
        'notes':                _notes.text.trim(),
        'appointment_datetime': _pickedDt!.toUtc().toIso8601String(),
        'remind_24h': _r24h,
        'remind_3h':  _r3h,
        'remind_2h':  _r2h,
        'remind_1h':  _r1h,
      };
      if (_isEdit) {
        await ApiService.updateAppointment(widget.existing!['id'], data);
      } else {
        await ApiService.createAppointment(data);
      }
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Edit Appointment' : 'Schedule Appointment',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildCard(children: [
              _field(_title, 'Title *', 'e.g. Cardiology check-up',
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
              const SizedBox(height: 14),
              // Date/time picker
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFFAFAFA),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Color(0xFF0EA5E9), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _pickedDt == null
                            ? 'Select date & time *'
                            : _fmt(_pickedDt!),
                        style: TextStyle(
                          fontSize: 14,
                          color: _pickedDt == null
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _field(_doctor, 'Doctor / Provider', 'Dr. Smith'),
              const SizedBox(height: 14),
              _field(_loc, 'Location / Clinic', 'City Hospital, Room 3B'),
              const SizedBox(height: 14),
              _field(_notes, 'Notes', 'Bring previous results, fasting required…',
                  maxLines: 3),
            ]),
            const SizedBox(height: 16),
            _buildCard(children: [
              Row(
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: Color(0xFF0EA5E9), size: 18),
                  const SizedBox(width: 8),
                  const Text('Remind me before',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.95,
                children: [
                  _reminderChip('24h', _r24h, (v) => setState(() => _r24h = v!)),
                  _reminderChip('3h',  _r3h,  (v) => setState(() => _r3h  = v!)),
                  _reminderChip('2h',  _r2h,  (v) => setState(() => _r2h  = v!)),
                  _reminderChip('1h',  _r1h,  (v) => setState(() => _r1h  = v!)),
                ],
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(_isEdit ? 'Save Changes' : 'Schedule Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _field(TextEditingController ctrl, String label, String hint,
      {int maxLines = 1, String? Function(String?)? validator}) =>
    TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  Widget _reminderChip(String label, bool value, ValueChanged<bool?> onChanged) {
    final active = value;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_outlined,
                size: 18,
                color: active ? const Color(0xFF0284C7) : const Color(0xFF94A3B8)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: active ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                )),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ·  $h:$m';
  }
}
