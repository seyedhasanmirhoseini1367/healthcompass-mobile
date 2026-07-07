import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email   = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading  = false;
  bool _sent     = false;

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.forgotPassword(_email.text.trim());
      if (mounted) setState(() { _sent = true; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _sent = true; _loading = false; }); // always show success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f7ff),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1e293b)),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: _sent ? _successView() : _formView(),
        ),
      ),
    );
  }

  Widget _formView() => Form(
    key: _formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        width: 72, height: 72,
        margin: const EdgeInsets.only(bottom: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFe0f2fe),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF0ea5e9), size: 38),
      ),
      const Text('Forgot Password?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1e293b))),
      const SizedBox(height: 8),
      const Text("No worries. Enter your email and we'll send you a reset link.",
          style: TextStyle(color: Color(0xFF64748b), fontSize: 14, height: 1.5)),
      const SizedBox(height: 28),
      TextFormField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
        decoration: InputDecoration(
          labelText: 'Email address',
          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0ea5e9)),
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
        ),
      ),
      const SizedBox(height: 22),
      ElevatedButton(
        onPressed: _loading ? null : _send,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0ea5e9),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Send Reset Link',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      const SizedBox(height: 20),
      Center(
        child: GestureDetector(
          onTap: () => context.go('/login'),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.arrow_back, size: 16, color: Color(0xFF0ea5e9)),
            SizedBox(width: 4),
            Text('Back to Sign In', style: TextStyle(color: Color(0xFF0ea5e9), fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]),
  );

  Widget _successView() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 40),
      Container(
        width: 80, height: 80,
        margin: const EdgeInsets.only(bottom: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFdcfce7), borderRadius: BorderRadius.circular(40)),
        child: const Icon(Icons.check_rounded, color: Color(0xFF22c55e), size: 44),
      ),
      const Text('Check your email', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1e293b))),
      const SizedBox(height: 10),
      Text('We sent a reset link to\n${_email.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748b), fontSize: 14, height: 1.6)),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: () => context.go('/login'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0ea5e9),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text('Back to Sign In',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      const SizedBox(height: 16),
      Center(
        child: GestureDetector(
          onTap: () => setState(() { _sent = false; _email.clear(); }),
          child: const Text('Resend email', style: TextStyle(color: Color(0xFF0ea5e9), fontWeight: FontWeight.w600)),
        ),
      ),
    ],
  );
}
