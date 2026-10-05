import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final workspaceState = ref.watch(workspacesProvider);
    final workspaces = workspaceState.valueOrNull ?? [];
    final selectedWorkspaceId = ref.watch(selectedWorkspaceProvider);
    final activeWorkspaceId =
        workspaces.any((workspace) => workspace.id == selectedWorkspaceId)
        ? selectedWorkspaceId
        : workspaces.isEmpty
        ? null
        : workspaces.first.id;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/branding/syncup-logo.png',
              width: 34,
              height: 34,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: workspaces.isEmpty
                  ? const Text('SyncUp')
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeWorkspaceId,
                        isDense: true,
                        items: workspaces
                            .map(
                              (workspace) => DropdownMenuItem(
                                value: workspace.id,
                                child: Text(workspace.name),
                              ),
                            )
                            .toList(),
                        onChanged: (workspaceId) {
                          ref.read(selectedWorkspaceProvider.notifier).state =
                              workspaceId;
                        },
                      ),
                    ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Create workspace',
            onPressed: () => context.push('/create-workspace'),
            icon: const Icon(Icons.add_business_outlined),
          ),
          IconButton(
            tooltip: 'Join workspace',
            onPressed: () => context.push('/join'),
            icon: const Icon(Icons.group_add_outlined),
          ),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(apiProvider).clear();
                if (!context.mounted) return;
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: tab == 0
          ? conversations.when(
              data: (items) {
                final visibleItems = activeWorkspaceId == null
                    ? items
                    : items
                          .where(
                            (item) => item.workspaceId == activeWorkspaceId,
                          )
                          .toList();
                return visibleItems.isEmpty
                    ? _empty(context)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: visibleItems.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 76),
                        itemBuilder: (_, i) =>
                            _conversation(context, visibleItems[i]),
                      );
              },
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(conversationsProvider),
                  child: const Text('Could not load conversations · retry'),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            )
          : tab == 1
          ? const _Channels()
          : const _Profile(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(icon: Icon(Icons.tag), label: 'Channels'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: tab == 0
          ? FloatingActionButton(
              onPressed: () => _newChat(context),
              child: const Icon(Icons.edit),
            )
          : tab == 1
          ? FloatingActionButton(
              onPressed: () => _newChannel(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _conversation(BuildContext context, dynamic d) => ListTile(
    onTap: () => context.push(
      '/chat/${d.id}?title=${Uri.encodeQueryComponent(d.title)}',
    ),
    leading: CircleAvatar(
      child: Text(d.title.isNotEmpty ? d.title[0].toUpperCase() : '?'),
    ),
    title: Row(
      children: [
        Expanded(
          child: Text(
            d.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (d.online) const Icon(Icons.circle, size: 10, color: Colors.green),
      ],
    ),
    subtitle: Text(
      d.lastMessage ?? 'Start a conversation',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: d.unreadCount > 0 ? Badge(label: Text('${d.unreadCount}')) : null,
  );
  Widget _empty(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Join a workspace or start a direct chat to get going.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/join'),
            icon: const Icon(Icons.group_add),
            label: const Text('Join workspace'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/create-workspace'),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Create workspace'),
          ),
        ],
      ),
    ),
  );

  Future<void> _newChat(BuildContext context) async {
    try {
      final api = ref.read(apiProvider);
      final workspaceResponse = await api.dio.get('/workspaces');
      final allWorkspaces = List<Map<String, dynamic>>.from(
        (workspaceResponse.data['workspaces'] as List).map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );
      final selectedWorkspaceId = ref.read(selectedWorkspaceProvider);
      final activeWorkspaceId =
          selectedWorkspaceId ??
          (allWorkspaces.isEmpty ? null : allWorkspaces.first['_id']);
      final workspaces = allWorkspaces
          .where((workspace) => workspace['_id'] == activeWorkspaceId)
          .toList();
      final currentUserId = ref.read(currentUserProvider)?['_id'];
      final candidates = <Map<String, dynamic>>[];
      for (final workspace in workspaces) {
        final membersResponse = await api.dio.get(
          '/workspaces/${workspace['_id']}/members',
        );
        for (final row in membersResponse.data['members'] as List) {
          final member = Map<String, dynamic>.from(row['userId']);
          if (member['_id'] == currentUserId) continue;
          candidates.add({
            ...member,
            'workspaceId': workspace['_id'],
            'workspaceName': workspace['name'],
          });
        }
      }
      if (!context.mounted) return;
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        builder: (_) => _DmMemberPicker(candidates: candidates),
      );
      if (selected == null || !context.mounted) return;
      final response = await api.dio.post(
        '/conversations/direct',
        data: {
          'userId': selected['_id'],
          'workspaceId': selected['workspaceId'],
        },
      );
      final conversationId = response.data['conversation']['_id'];
      ref.invalidate(conversationsProvider);
      if (context.mounted) {
        final title = Uri.encodeQueryComponent(selected['displayName']);
        context.push('/chat/$conversationId?title=$title');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load workspace members.')),
        );
      }
    }
  }

  Future<void> _newChannel(BuildContext context) async {
    final workspaces = ref.read(workspacesProvider).valueOrNull ?? [];
    final selectedWorkspaceId = ref.read(selectedWorkspaceProvider);
    final workspaceId =
        workspaces.any((workspace) => workspace.id == selectedWorkspaceId)
        ? selectedWorkspaceId
        : workspaces.isEmpty
        ? null
        : workspaces.first.id;
    if (workspaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create or join a workspace first.')),
      );
      return;
    }
    final name = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New channel'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Channel name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (confirmed != true || name.text.trim().isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(apiProvider)
          .dio
          .post(
            '/workspaces/$workspaceId/channels',
            data: {'name': name.text.trim(), 'visibility': 'public'},
          );
      ref.invalidate(conversationsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create channel.')),
        );
      }
    }
  }
}

class _Channels extends ConsumerWidget {
  const _Channels();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(conversationsProvider);
    final workspaces = ref.watch(workspacesProvider).valueOrNull ?? [];
    final selectedWorkspaceId = ref.watch(selectedWorkspaceProvider);
    final activeWorkspaceId =
        workspaces.any((workspace) => workspace.id == selectedWorkspaceId)
        ? selectedWorkspaceId
        : workspaces.isEmpty
        ? null
        : workspaces.first.id;
    return channels.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(conversationsProvider),
          child: const Text('Retry loading channels'),
        ),
      ),
      data: (items) {
        final channelItems = items
            .where(
              (item) =>
                  item.kind == 'channel' &&
                  (activeWorkspaceId == null ||
                      item.workspaceId == activeWorkspaceId),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Your channels',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (channelItems.isEmpty) const Text('No channels yet.'),
            ...channelItems.map(
              (channel) => Card(
                child: ListTile(
                  leading: const Icon(Icons.tag),
                  title: Text(channel.title),
                  subtitle: Text(
                    channel.channelName == 'general'
                        ? 'Welcome to your workspace'
                        : 'Team channel',
                  ),
                  onTap: () => context.push(
                    '/chat/${channel.id}?title=${Uri.encodeQueryComponent(channel.title)}',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Profile extends ConsumerWidget {
  const _Profile();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final display = (user?['displayName'] ?? 'Your profile').toString();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CircleAvatar(
          radius: 38,
          child: Text(
            display.isEmpty ? 'R' : display.substring(0, 1).toUpperCase(),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(display, style: Theme.of(context).textTheme.titleLarge),
        ),
        Center(child: Text(user?['email'] ?? '')),
        const SizedBox(height: 28),
        const ListTile(
          leading: Icon(Icons.notifications_none),
          title: Text('Notifications'),
          trailing: Icon(Icons.chevron_right),
        ),
        const ListTile(
          leading: Icon(Icons.palette_outlined),
          title: Text('Appearance'),
          subtitle: Text('Follows system theme'),
        ),
      ],
    );
  }
}

class _DmMemberPicker extends StatefulWidget {
  final List<Map<String, dynamic>> candidates;
  const _DmMemberPicker({required this.candidates});
  @override
  State<_DmMemberPicker> createState() => _DmMemberPickerState();
}

class _DmMemberPickerState extends State<_DmMemberPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.candidates.where((user) {
      final username = (user['displayName'] ?? '').toString().toLowerCase();
      return username.contains(query.toLowerCase());
    }).toList();
    return SafeArea(
      child: SizedBox(
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'New direct message',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search username',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No matching workspace members.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, index) {
                        final user = filtered[index];
                        final username = (user['displayName'] ?? 'Member')
                            .toString();
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(username[0].toUpperCase()),
                          ),
                          title: Text(username),
                          subtitle: Text(
                            '${user['workspaceName']} · ${user['email']}',
                          ),
                          onTap: () => Navigator.pop(context, user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
