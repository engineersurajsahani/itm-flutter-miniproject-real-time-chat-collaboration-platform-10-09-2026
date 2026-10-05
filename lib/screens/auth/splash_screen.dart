import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final api = ref.read(apiProvider);
    final token = await api.storage.read(key: 'accessToken');
    if (token == null) {
      if (mounted) context.go('/login');
      return;
    }
    try {
      final response = await api.dio.get('/auth/me');
      ref.read(currentUserProvider.notifier).state = Map<String, dynamic>.from(
        response.data['user'],
      );
      if (mounted) context.go('/home');
    } catch (_) {
      await api.clear();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/branding/syncup-logo.png', width: 84, height: 84),
          const SizedBox(height: 16),
          Text(
            'SyncUp',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
