import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';

class JoinWorkspaceScreen extends ConsumerStatefulWidget {
  const JoinWorkspaceScreen({super.key});
  @override
  ConsumerState<JoinWorkspaceScreen> createState() => _JoinState();
}

class _JoinState extends ConsumerState<JoinWorkspaceScreen> {
  final code = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> join() async {
    setState(() => loading = true);
    try {
      final response = await ref
          .read(apiProvider)
          .dio
          .post(
            '/workspaces/join',
            data: {'code': code.text.trim().toUpperCase()},
          );
      ref.invalidate(conversationsProvider);
      ref.invalidate(workspacesProvider);
      ref.read(selectedWorkspaceProvider.notifier).state =
          response.data['workspace']['_id'];
      if (mounted) {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'That join code is not valid or has expired.');
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
      appBar: AppBar(title: const Text('Join workspace')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Have a workspace code?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Enter the code shared by your workspace owner.'),
            const SizedBox(height: 24),
            TextField(
              controller: code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Join code',
                prefixIcon: Icon(Icons.key),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: TextStyle(color: colors.error)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loading ? null : join,
              child: Text(loading ? 'Joining…' : 'Join workspace'),
            ),
          ],
        ),
      ),
    );
  }
}
