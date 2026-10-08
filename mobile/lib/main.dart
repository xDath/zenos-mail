import 'package:flutter/material.dart';

import 'screens/mail_shell.dart';
import 'services/zenos_api.dart';
import 'theme/zenos_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZenosMailApp());
}

class ZenosMailApp extends StatelessWidget {
  const ZenosMailApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenos Mail',
      debugShowCheckedModeBanner: false,
      theme: buildZenosTheme(),
      home: home ?? const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final _api = ZenosApi();
  bool? _authenticated;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final authenticated = await _api.restoreSession();
    if (mounted) setState(() => _authenticated = authenticated);
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated == null) return const _LaunchScreen();
    if (_authenticated == false) {
      return LoginScreen(
        api: _api,
        onAuthenticated: () => setState(() => _authenticated = true),
      );
    }
    return MailShell(
      api: _api,
      onLogout: () => setState(() => _authenticated = false),
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.onAuthenticated,
  });

  final ZenosApi api;
  final VoidCallback onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _password = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_submitting || _password.text.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.api.login(_password.text);
      widget.onAuthenticated();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ZenosColors.ink,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Image.asset('assets/brand/zenos-logo.png'),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'ZENOS',
                    style: TextStyle(
                      color: ZenosColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Text(
                    '.',
                    style: TextStyle(
                      color: ZenosColors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),
              Text(
                'Masuk ke email.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Satu kotak masuk untuk zenos.studio dan alte.codes.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 34),
              TextField(
                controller: _password,
                obscureText: _obscure,
                autofocus: true,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _login,
                style: FilledButton.styleFrom(
                  backgroundColor: ZenosColors.ink,
                  foregroundColor: ZenosColors.ground,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Masuk'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
