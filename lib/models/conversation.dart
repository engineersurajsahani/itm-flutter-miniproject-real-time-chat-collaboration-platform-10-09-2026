class Conversation {
  final String id, title, kind;
  final String? workspaceId, channelName, lastMessage;
  final int unreadCount;
  final bool online;
  const Conversation({
    required this.id,
    required this.title,
    required this.kind,
    this.workspaceId,
    this.channelName,
    this.lastMessage,
    this.unreadCount = 0,
    this.online = false,
  });
  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: j['_id'] ?? j['id'] ?? '',
    title: j['title'] ?? j['name'] ?? 'Conversation',
    kind: j['kind'] ?? j['type'] ?? 'direct',
    workspaceId: j['workspaceId'],
    channelName: j['channelName'],
    lastMessage: j['lastMessage'] is Map
        ? j['lastMessage']['text']
        : j['lastMessage'],
    unreadCount: j['unreadCount'] ?? 0,
    online: j['online'] ?? false,
  );
}
