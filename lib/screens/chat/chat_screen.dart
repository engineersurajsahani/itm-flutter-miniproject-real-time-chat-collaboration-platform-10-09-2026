import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import '../../models/message.dart';
import '../../providers/app_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String title;
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });
  @override
  ConsumerState<ChatScreen> createState() => _ChatState();
}

class _ChatState extends ConsumerState<ChatScreen> {
  final input = TextEditingController();
  Message? reply;
  Timer? typingTimer;
  String? typingName;
  bool uploading = false;
  @override
  void initState() {
    super.initState();
    ref.read(socketProvider).connect().then((socket) {
      socket.emit('conversation:join', {
        'conversationId': widget.conversationId,
      });
      socket.on(
        'message:new',
        (_) => ref.invalidate(messagesProvider(widget.conversationId)),
      );
      socket.on(
        'message:updated',
        (_) => ref.invalidate(messagesProvider(widget.conversationId)),
      );
      socket.on(
        'message:deleted',
        (_) => ref.invalidate(messagesProvider(widget.conversationId)),
      );
      socket.on('typing:update', (data) {
        if (!mounted ||
            data['userId'] == ref.read(currentUserProvider)?['_id']) {
          return;
        }
        setState(() {
          typingName = data['typing'] == true
              ? (data['displayName'] ?? 'Someone')
              : null;
        });
      });
    });
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    ref.read(socketProvider).socket?.emit('typing:stop', {
      'conversationId': widget.conversationId,
    });
    ref.read(socketProvider).socket?.emit('conversation:leave', {
      'conversationId': widget.conversationId,
    });
    input.dispose();
    super.dispose();
  }

  void _typingChanged(String value) {
    final socket = ref.read(socketProvider).socket;
    if (value.trim().isEmpty) {
      typingTimer?.cancel();
      socket?.emit('typing:stop', {'conversationId': widget.conversationId});
      return;
    }
    socket?.emit('typing:start', {'conversationId': widget.conversationId});
    typingTimer?.cancel();
    typingTimer = Timer(const Duration(milliseconds: 900), () {
      socket?.emit('typing:stop', {'conversationId': widget.conversationId});
    });
  }

  void send({List<Map<String, dynamic>> attachments = const []}) {
    final text = input.text.trim();
    if (text.isEmpty && attachments.isEmpty) return;
    final clientId = 'mobile-${DateTime.now().microsecondsSinceEpoch}';
    ref.read(socketProvider).socket?.emitWithAck('message:send', {
      'conversationId': widget.conversationId,
      'text': text,
      'clientId': clientId,
      'replyTo': reply?.id,
      'attachments': attachments,
    }, ack: (_) => ref.invalidate(messagesProvider(widget.conversationId)));
    input.clear();
    typingTimer?.cancel();
    ref.read(socketProvider).socket?.emit('typing:stop', {
      'conversationId': widget.conversationId,
    });
    setState(() => reply = null);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.conversationId));
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              typingName == null ? 'online' : '$typingName is typing…',
              style: TextStyle(
                fontSize: 12,
                color: typingName == null
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Conversation details',
            onPressed: () => _showConversationDetails(context),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              data: (items) => items.isEmpty
                  ? const Center(child: Text('Say hello 👋'))
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (_, i) =>
                          _bubble(context, items[items.length - 1 - i]),
                    ),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () =>
                      ref.invalidate(messagesProvider(widget.conversationId)),
                  child: const Text('Retry loading messages'),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          if (reply != null)
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reply!.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => reply = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: uploading ? null : () => _attach(context),
                    icon: uploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: input,
                      onChanged: _typingChanged,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Write a message…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: send,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, Message message) => Align(
    alignment: message.mine ? Alignment.centerRight : Alignment.centerLeft,
    child: GestureDetector(
      onLongPress: () => _messageActions(context, message),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.mine)
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Text(
              message.deleted ? 'Message deleted' : message.text,
              style: TextStyle(
                fontStyle: message.deleted ? FontStyle.italic : null,
              ),
            ),
            if (!message.deleted && message.attachments.isNotEmpty)
              ...message.attachments.map(
                (attachment) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _attachmentPreview(context, attachment),
                ),
              ),
            const SizedBox(height: 3),
            Text(
              '${DateFormat('HH:mm').format(message.createdAt)}${message.edited ? ' · edited' : ''}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _attachmentPreview(BuildContext context, Attachment attachment) {
    if (!attachment.mimeType.startsWith('image/')) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined),
            const SizedBox(width: 8),
            Flexible(
              child: Text(attachment.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
    }
    return Semantics(
      button: true,
      label: 'Open ${attachment.name}',
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          barrierColor: Colors.black87,
          builder: (dialogContext) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    child: Image.network(
                      attachment.url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text(
                        'Could not load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 260,
            height: 180,
            child: Image.network(
              attachment.url,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Colors.black12,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _attach(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(
      withData: kIsWeb,
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'pdf',
        'doc',
        'docx',
        'txt',
      ],
    );
    final file = picked?.files.single;
    if (file == null || !context.mounted) return;
    if ((kIsWeb && file.bytes == null) || (!kIsWeb && file.path == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The selected file could not be read.')),
      );
      return;
    }
    setState(() => uploading = true);
    try {
      final multipart = kIsWeb
          ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
          : await MultipartFile.fromFile(file.path!, filename: file.name);
      final form = FormData.fromMap({'file': multipart});
      final response = await ref
          .read(apiProvider)
          .dio
          .post('/uploads', data: form);
      send(
        attachments: [Map<String, dynamic>.from(response.data['attachment'])],
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _showConversationDetails(BuildContext context) async {
    final details = ref
        .read(apiProvider)
        .dio
        .get('/conversations/${widget.conversationId}/details');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ConversationDetailsSheet(details: details),
    );
  }

  Future<void> _messageActions(BuildContext context, Message message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () => Navigator.pop(context, 'reply'),
            ),
            if (message.mine && !message.deleted)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            if (message.mine && !message.deleted)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'reply') setState(() => reply = message);
    if (action == 'delete') {
      await ref.read(apiProvider).dio.delete('/messages/${message.id}');
      ref.invalidate(messagesProvider(widget.conversationId));
    }
    if (action == 'edit') {
      if (!context.mounted) return;
      final controller = TextEditingController(text: message.text);
      final updated = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Edit message'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (updated != null && updated.isNotEmpty) {
        await ref
            .read(apiProvider)
            .dio
            .patch('/messages/${message.id}', data: {'text': updated});
        ref.invalidate(messagesProvider(widget.conversationId));
      }
    }
  }
}

class _ConversationDetailsSheet extends StatelessWidget {
  final Future<Response<dynamic>> details;
  const _ConversationDetailsSheet({required this.details});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: FutureBuilder<Response<dynamic>>(
        future: details,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load details.'));
          }
          final data = Map<String, dynamic>.from(snapshot.data!.data);
          final members = List<Map<String, dynamic>>.from(
            (data['members'] as List).map(
              (member) => Map<String, dynamic>.from(member),
            ),
          );
          final workspace = data['workspace'] == null
              ? null
              : Map<String, dynamic>.from(data['workspace']);
          final isGroup = data['kind'] == 'channel';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGroup
                          ? (workspace == null
                                ? 'Group details'
                                : workspace['name'] ?? 'Group details')
                          : 'Direct message',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                    ),
                  ],
                ),
              ),
              if (isGroup && workspace != null && workspace['joinCode'] != null)
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.key_outlined),
                    title: const Text('Workspace join code'),
                    subtitle: SelectableText(
                      workspace['joinCode'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Copy code',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: workspace['joinCode']),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Join code copied')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Members',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (_, index) {
                    final member = members[index];
                    final username = (member['displayName'] ?? 'Member')
                        .toString();
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(username[0].toUpperCase()),
                      ),
                      title: Text(username),
                      subtitle: Text(member['email'] ?? ''),
                      trailing: member['role'] == null
                          ? null
                          : Text(member['role'].toString()),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
