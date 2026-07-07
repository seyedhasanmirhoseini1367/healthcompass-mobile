import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _confirm  = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _loading   = false;
  bool _obscure1  = true;
  bool _obscure2  = true;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.register(_email.text.trim(), _password.text, _name.text.trim());
      if (mounted) context.go('/dashboard');
    } on Exception catch (e) {
      setState(() { _error = _parseError(e.toString()); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _parseError(String raw) {
    if (raw.contains('400')) return 'Email already registered or invalid data.';
    if (raw.contains('connect')) return 'Cannot connect to server. Try again.';
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _logo(),
                const SizedBox(height: 20),
                const Text('Create Account', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1e293b))),
                const SizedBox(height: 4),
                const Text('Join HealthCompass today', textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
                const SizedBox(height: 28),

                _field(_name,  'Full Name',  Icons.person_outline,  validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your full name' : null),
                const SizedBox(height: 14),
                _field(_email, 'Email',      Icons.email_outlined,
                    type: TextInputType.emailAddress, validator: (v) =>
                    v == null || !v.contains('@') ? 'Enter a valid email' : null),
                const SizedBox(height: 14),
                _passwordField(_password, 'Password', _obscure1,
                    () => setState(() => _obscure1 = !_obscure1),
                    validator: (v) => v == null || v.length < 8 ? 'Min 8 characters' : null),
                const SizedBox(height: 14),
                _passwordField(_confirm, 'Confirm Password', _obscure2,
                    () => setState(() => _obscure2 = !_obscure2),
                    validator: (v) => v != _password.text ? 'Passwords do not match' : null),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFfee2e2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFdc2626), fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0ea5e9),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account? ', style: TextStyle(color: Color(0xFF64748b))),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Sign In',
                        style: TextStyle(color: Color(0xFF0ea5e9), fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() => Center(
    child: Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF6366f1)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF0ea5e9).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 38),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text, String? Function(String?)? validator}) =>
    TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      decoration: _dec(label, icon),
    );

  Widget _passwordField(TextEditingController ctrl, String label, bool obscure,
      VoidCallback toggle, {String? Function(String?)? validator}) =>
    TextFormField(
      controller: ctrl,
      obscureText: obscure,
      validator: validator,
      decoration: _dec(label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF94a3b8)), onPressed: toggle),
      ),
    );

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF0ea5e9)),
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0ea5e9), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFef4444))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.5)),
  );

}
