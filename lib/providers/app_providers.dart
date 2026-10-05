import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/workspace.dart';
import '../services/api_client.dart';
import '../services/socket_service.dart';

final apiProvider = Provider((_) => ApiClient());
final socketProvider = Provider((_) => SocketService());
final currentUserProvider = StateProvider<Map<String, dynamic>?>((_) => null);
final selectedWorkspaceProvider = StateProvider<String?>((_) => null);
final workspacesProvider = FutureProvider<List<Workspace>>((ref) async {
  final response = await ref.read(apiProvider).dio.get('/workspaces');
  return (response.data['workspaces'] as List)
      .map((item) => Workspace.fromJson(Map<String, dynamic>.from(item)))
      .toList();
});
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final r = await ref.read(apiProvider).dio.get('/conversations');
  return ((r.data['conversations'] ?? r.data) as List)
      .map((e) => Conversation.fromJson(e))
      .toList();
});
final messagesProvider = FutureProvider.family<List<Message>, String>((
  ref,
  id,
) async {
  final r = await ref.read(apiProvider).dio.get('/conversations/$id/messages');
  final user = ref.read(currentUserProvider);
  return ((r.data['messages'] ?? r.data) as List)
      .map((e) => Message.fromJson(e, currentUserId: user?['_id']))
      .toList();
});
