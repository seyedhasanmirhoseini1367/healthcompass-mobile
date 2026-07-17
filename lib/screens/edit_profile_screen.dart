import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../core/api_service.dart';
import '../models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile user;
  const EditProfileScreen({super.key, required this.user});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey       = GlobalKey<FormState>();
  late final _firstNameCtrl = TextEditingController(text: widget.user.firstName);
  late final _lastNameCtrl  = TextEditingController(text: widget.user.lastName);
  late final _phoneCtrl     = TextEditingController(text: widget.user.phoneNumber ?? '');
  String? _dob;
  bool   _saving     = false;
  bool   _uploading  = false;
  String? _error;
  String? _picUrl;

  @override
  void initState() {
    super.initState();
    _dob    = widget.user.dateOfBirth;
    _picUrl = widget.user.profilePicture;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    DateTime initial = DateTime(1990);
    if (_dob != null) { try { initial = DateTime.parse(_dob!); } catch (_) {} }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF0ea5e9))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dob = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}');
    }
  }

  Future<void> _pickProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;
    setState(() { _uploading = true; _error = null; });
    try {
      final updated = await ApiService.uploadProfilePicture(file.bytes!, file.name);
      setState(() {
        _picUrl   = updated['profile_picture']?.toString();
        _uploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!'),
              backgroundColor: Color(0xFF22c55e)));
      }
    } catch (_) {
      setState(() { _error = 'Could not upload picture. Please try again.'; _uploading = false; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ApiService.updateProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName:  _lastNameCtrl.text.trim(),
        phone:     _phoneCtrl.text.trim(),
        dob:       _dob,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Color(0xFF22c55e)));
        context.pop(true);
      }
    } catch (_) {
      setState(() { _error = 'Could not save. Please try again.'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${widget.user.firstName} ${widget.user.lastName}'.trim();
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : (widget.user.username.isNotEmpty ? widget.user.username : '?')[0].toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // ── Profile picture ─────────────────────────────────────────────
            Center(child: Stack(children: [
              GestureDetector(
                onTap: _uploading ? null : _pickProfilePicture,
                child: Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0ea5e9), width: 2.5),
                  ),
                  child: ClipOval(child: _uploading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9), strokeWidth: 2))
                      : (_picUrl != null && _picUrl!.isNotEmpty && _picUrl!.startsWith('http'))
                          ? Image.network(_picUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _avatar(initials))
                          : _avatar(initials)),
                ),
              ),
              Positioned(bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _uploading ? null : _pickProfilePicture,
                  child: Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0ea5e9), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ])),
            const SizedBox(height: 6),
            const Center(child: Text('Tap to change photo',
                style: TextStyle(color: Color(0xFF94a3b8), fontSize: 12))),
            const SizedBox(height: 24),

            // ── Form fields ─────────────────────────────────────────────────
            _field('First Name', _firstNameCtrl),
            const SizedBox(height: 14),
            _field('Last Name',  _lastNameCtrl),
            const SizedBox(height: 14),
            _field('Phone Number', _phoneCtrl, keyboard: TextInputType.phone),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDob,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFe2e8f0))),
                child: Row(children: [
                  const Icon(Icons.cake_outlined, size: 18, color: Color(0xFF94a3b8)),
                  const SizedBox(width: 10),
                  Text(_dob ?? 'Date of birth (optional)',
                      style: TextStyle(
                        color: _dob != null ? const Color(0xFF1e293b) : const Color(0xFF94a3b8),
                        fontSize: 14)),
                  const Spacer(),
                  if (_dob != null)
                    GestureDetector(
                      onTap: () => setState(() => _dob = null),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFF94a3b8)),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFdc2626), fontSize: 13)),
              ),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0ea5e9), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _avatar(String initials) => Container(
    color: const Color(0xFF0ea5e9).withValues(alpha: 0.15),
    child: Center(child: Text(initials,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0ea5e9)))),
  );

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text}) =>
    TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        filled: true, fillColor: Colors.white,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0ea5e9), width: 1.5)),
      ),
    );
}
