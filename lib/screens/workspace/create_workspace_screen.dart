import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../providers/app_providers.dart';

class CreateWorkspaceScreen extends ConsumerStatefulWidget {
  const CreateWorkspaceScreen({super.key});
  @override
  ConsumerState<CreateWorkspaceScreen> createState() => _CreateWorkspaceState();
}

class _CreateWorkspaceState extends ConsumerState<CreateWorkspaceScreen> {
  final name = TextEditingController();
  bool loading = false;
  String? code;

  Future<void> create() async {
    setState(() => loading = true);
    try {
      final response = await ref
          .read(apiProvider)
          .dio
          .post('/workspaces', data: {'name': name.text.trim()});
      if (!mounted) return;
      setState(() => code = response.data['joinCode']);
      ref.read(selectedWorkspaceProvider.notifier).state =
          response.data['workspace']['_id'];
      ref.invalidate(conversationsProvider);
      ref.invalidate(workspacesProvider);
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create workspace.')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (code != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workspace created')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Share this join code',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Your teammates can use it to join this workspace.'),
              const SizedBox(height: 24),
              SelectableText(
                code!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(letterSpacing: 5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Create workspace')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Start a new team space',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('You’ll become the workspace owner.'),
            const SizedBox(height: 24),
            TextField(
              controller: name,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Workspace name'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loading || name.text.trim().length < 2 ? null : create,
              child: Text(loading ? 'Creating…' : 'Create workspace'),
            ),
          ],
        ),
      ),
    );
  }
}
