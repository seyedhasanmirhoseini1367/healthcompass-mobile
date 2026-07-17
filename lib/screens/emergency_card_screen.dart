import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/user_profile.dart';

class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key});
  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  EmergencyCard? _data;
  bool _loading = true;
  bool _editing = false;

  final _bloodTypeCtrl    = TextEditingController();
  final _allergiesCtrl    = TextEditingController();
  final _contactNameCtrl  = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  bool _saving = false;

  static const _bloodTypes = ['', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _bloodTypeCtrl.dispose(); _allergiesCtrl.dispose();
    _contactNameCtrl.dispose(); _contactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.emergencyCard();
      setState(() {
        _data = data;
        _bloodTypeCtrl.text    = data.bloodType;
        _allergiesCtrl.text    = data.allergies;
        _contactNameCtrl.text  = data.emergencyContactName;
        _contactPhoneCtrl.text = data.emergencyContactPhone;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await ApiService.updateEmergencyCard(
        bloodType:    _bloodTypeCtrl.text,
        allergies:    _allergiesCtrl.text,
        contactName:  _contactNameCtrl.text,
        contactPhone: _contactPhoneCtrl.text,
      );
      setState(() { _data = updated; _editing = false; _saving = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency card updated!'),
              backgroundColor: Color(0xFF22c55e)));
      }
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Emergency Card', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFFef4444),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_loading && _data != null)
            TextButton(
              onPressed: () => setState(() => _editing = !_editing),
              child: Text(_editing ? 'Cancel' : 'Edit',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFef4444)))
          : _data == null
              ? const Center(child: Text('Could not load data.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _editing ? _editForm() : _cardView(),
                ),
    );
  }

  Widget _cardView() => Column(children: [
    // Red emergency card header
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFef4444),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
          SizedBox(width: 10),
          Text('MEDICAL EMERGENCY CARD',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        ]),
        const SizedBox(height: 16),
        Text(_data!.fullName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        if ((_data!.dateOfBirth ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('DOB: ${_data!.dateOfBirth}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ]),
    ),
    const SizedBox(height: 16),

    _infoCard([
      _infoRow(Icons.bloodtype_rounded, 'Blood Type',
          _data!.bloodType.isEmpty ? 'Not set' : _data!.bloodType,
          valueColor: _data!.bloodType.isNotEmpty ? const Color(0xFFef4444) : null),
      _infoRow(Icons.warning_amber_rounded, 'Allergies',
          _data!.allergies.isEmpty ? 'None listed' : _data!.allergies),
    ]),
    const SizedBox(height: 14),

    _infoCard([
      _infoRow(Icons.phone_in_talk_rounded, 'Emergency Contact',
          _data!.emergencyContactName.isEmpty ? 'Not set' : _data!.emergencyContactName),
      _infoRow(Icons.phone_rounded, 'Contact Phone',
          _data!.emergencyContactPhone.isEmpty ? 'Not set' : _data!.emergencyContactPhone),
    ]),
    const SizedBox(height: 14),

    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFfed7aa)),
      ),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFFf59e0b), size: 18),
        SizedBox(width: 10),
        Expanded(child: Text(
          'This card can be shared with emergency responders. Tap Edit to update your information.',
          style: TextStyle(color: Color(0xFF92400e), fontSize: 12, height: 1.4),
        )),
      ]),
    ),
  ]);

  Widget _infoCard(List<Widget> rows) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe2e8f0))),
    child: Column(children: rows),
  );

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94a3b8)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748b), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14,
            color: valueColor ?? const Color(0xFF1e293b),
          )),
        ])),
      ]));

  Widget _editForm() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Blood Type', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748b), fontSize: 13)),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _bloodTypes.contains(_bloodTypeCtrl.text) ? _bloodTypeCtrl.text : '',
          isExpanded: true,
          items: _bloodTypes.map((t) => DropdownMenuItem(
            value: t, child: Text(t.isEmpty ? 'Select blood type' : t))).toList(),
          onChanged: (v) => setState(() => _bloodTypeCtrl.text = v ?? ''),
        ),
      ),
    ),
    const SizedBox(height: 14),
    _editField('Allergies (comma separated)', _allergiesCtrl, maxLines: 3),
    const SizedBox(height: 14),
    _editField('Emergency Contact Name',  _contactNameCtrl),
    const SizedBox(height: 14),
    _editField('Emergency Contact Phone', _contactPhoneCtrl, keyboard: TextInputType.phone),
    const SizedBox(height: 24),
    ElevatedButton(
      onPressed: _saving ? null : _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFef4444), foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _saving
          ? const SizedBox(height: 20, width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Save Emergency Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ),
  ]);

  Widget _editField(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) =>
    TextFormField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboard,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label, filled: true, fillColor: Colors.white,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.5)),
      ),
    );
}
