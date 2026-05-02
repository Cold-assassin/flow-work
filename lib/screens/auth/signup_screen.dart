import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/theme.dart';
import '../../services/supabase_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailcontroller = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isloading = false;
  bool _hidepassword = true;
  String? _errormessege;
  bool _success = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isloading = true; _errormessege = null; });
    try {
      await SupabaseService().signUp(
        email: _emailcontroller.text.trim(),
        password: _passCtrl.text,
        fullName: _nameCtrl.text.trim(),
      );
      setState(() => _success = true);
    } on AuthException catch (e) {
      setState(() => _errormessege = e.message);
    } finally {
      if (mounted) setState(() => _isloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppTheme.second.withOpacity(0.15), AppTheme.background],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.first,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.bolt, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 12),
                      Text('TaskFlow',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                  const SizedBox(height: 40),
                  if (_success)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: AppTheme.success, size: 40),
                          ),
                          const SizedBox(height: 16),
                          Text('Check your email!',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('We sent a confirmation link to ${_emailcontroller.text}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Back to Login', style: TextStyle(color: AppTheme.first)),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Create account', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 24),
                            if (_errormessege != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(_errormessege!, style: TextStyle(color: AppTheme.danger)),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => (v?.isNotEmpty == true) ? null : 'Required',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailcontroller,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) => v?.contains('@') == true ? null : 'Invalid email',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _hidepassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(_hidepassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _hidepassword = !_hidepassword),
                                ),
                              ),
                              validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Min 6 characters',
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isloading ? null : _signup,
                                child: _isloading
                                    ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Create Account'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (!_success)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: Theme.of(context).textTheme.bodyMedium),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Sign In', style: TextStyle(color: AppTheme.first)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}