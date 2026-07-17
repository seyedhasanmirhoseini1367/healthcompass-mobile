import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';
import '../core/error_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _loading   = false;
  bool _obscure   = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.login(_email.text.trim(), _password.text);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() { _error = isConnectivityIssue(e) ? friendlyError(e) : 'Invalid email or password.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
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
                const SizedBox(height: 20),
                _logo(),
                const SizedBox(height: 20),
                const Text('HealthCompass', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                        color: Color(0xFF1e293b), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                const Text('Your personal health companion', textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
                const SizedBox(height: 36),

                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  decoration: _dec('Email', Icons.email_outlined),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
                  decoration: _dec('Password', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF94a3b8)),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: const Text('Forgot password?',
                        style: TextStyle(color: Color(0xFF0ea5e9), fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFfee2e2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFdc2626), fontSize: 13)),
                  ),
                  const SizedBox(height: 14),
                ],

                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0ea5e9),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Sign In',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 24),

                Row(children: const [
                  Expanded(child: Divider(color: Color(0xFFe2e8f0))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 13))),
                  Expanded(child: Divider(color: Color(0xFFe2e8f0))),
                ]),
                const SizedBox(height: 24),

                OutlinedButton(
                  onPressed: () => context.go('/register'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF0ea5e9), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create New Account',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0ea5e9))),
                ),
                const SizedBox(height: 28),

                const Center(
                  child: Text('Research Prototype — Not a real healthcare service',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94a3b8), fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() => Center(
    child: Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF6366f1)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: const Color(0xFF0ea5e9).withValues(alpha: 0.35),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 44),
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
