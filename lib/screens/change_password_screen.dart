import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _oldCtrl   = TextEditingController();
  final _newCtrl   = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _showOld    = false;
  bool _showNew    = false;
  bool _showConf   = false;
  bool _saving     = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose(); _newCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ApiService.changePassword(
        oldPassword: _oldCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed! Please log in again.'),
              backgroundColor: Color(0xFF22c55e)));
        await ApiService.logout();
        if (mounted) context.go('/login');
      }
    } on Exception catch (e) {
      final msg = e.toString().contains('incorrect')
          ? 'Current password is incorrect.'
          : 'Failed to change password. Please try again.';
      setState(() { _error = msg; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1e293b),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _pwField('Current Password', _oldCtrl, _showOld, () => setState(() => _showOld = !_showOld)),
            const SizedBox(height: 14),
            _pwField('New Password',     _newCtrl, _showNew, () => setState(() => _showNew = !_showNew),
                validator: (v) => (v != null && v.length >= 8) ? null : 'Min 8 characters'),
            const SizedBox(height: 14),
            _pwField('Confirm New Password', _confCtrl, _showConf, () => setState(() => _showConf = !_showConf),
                validator: (v) => v == _newCtrl.text ? null : 'Passwords do not match'),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFfee2e2), borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFdc2626), fontSize: 13)),
              ),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0ea5e9), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _pwField(String label, TextEditingController ctrl, bool show, VoidCallback toggle,
      {String? Function(String?)? validator}) =>
    TextFormField(
      controller: ctrl,
      obscureText: !show,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        filled: true, fillColor: Colors.white,
        suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF94a3b8)), onPressed: toggle),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0ea5e9), width: 1.5)),
      ),
      validator: validator ?? (v) => (v != null && v.isNotEmpty) ? null : 'Required',
    );
}
