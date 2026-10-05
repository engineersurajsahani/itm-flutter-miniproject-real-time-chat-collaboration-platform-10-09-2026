import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;
  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final api = ref.read(apiProvider);
      final response = await api.dio.post(
        '/auth/login',
        data: {
          'email': email.text.trim().toLowerCase(),
          'password': password.text,
        },
      );
      await api.saveTokens(response.data);
      ref.read(currentUserProvider.notifier).state = Map<String, dynamic>.from(
        response.data['user'],
      );
      if (mounted) {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Could not sign in. Check your details and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/branding/syncup-logo.png',
                      width: 58,
                      height: 58,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SyncUp',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Team conversations, in sync.'),
                const SizedBox(height: 36),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(error!, style: TextStyle(color: colors.error)),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading ? null : login,
                  child: Text(loading ? 'Signing in…' : 'Sign in'),
                ),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
