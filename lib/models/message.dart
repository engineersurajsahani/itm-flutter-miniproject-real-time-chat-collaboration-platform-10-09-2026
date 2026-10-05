class Attachment {
  final String url, name, mimeType;
  final int size;
  const Attachment({
    required this.url,
    required this.name,
    required this.mimeType,
    required this.size,
  });
  factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
    url: j['url'] ?? '',
    name: j['name'] ?? 'file',
    mimeType: j['mimeType'] ?? '',
    size: j['size'] ?? 0,
  );
}

class Message {
  final String id, conversationId, senderId, senderName, text, clientId;
  final DateTime createdAt;
  final bool edited, deleted, mine;
  final List<Attachment> attachments;
  final String? replyTo;
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.clientId,
    required this.createdAt,
    required this.edited,
    required this.deleted,
    required this.mine,
    this.attachments = const [],
    this.replyTo,
  });
  factory Message.fromJson(Map<String, dynamic> j, {String? currentUserId}) =>
      Message(
        id: j['_id'] ?? j['id'] ?? '',
        conversationId: j['conversationId'] ?? '',
        senderId: j['senderId'] is Map
            ? j['senderId']['_id']
            : (j['senderId'] ?? ''),
        senderName: j['senderId'] is Map
            ? (j['senderId']['displayName'] ??
                  j['senderId']['email'] ??
                  'Teammate')
            : (j['senderName'] ?? 'Teammate'),
        text: j['text'] ?? '',
        clientId: j['clientId'] ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        edited: j['editedAt'] != null,
        deleted: j['deletedAt'] != null || j['deleted'] == true,
        mine:
            currentUserId != null &&
            (j['senderId'] is Map ? j['senderId']['_id'] : j['senderId']) ==
                currentUserId,
        attachments: ((j['attachments'] ?? []) as List)
            .map((a) => Attachment.fromJson(a))
            .toList(),
        replyTo: j['replyTo'],
      );
}
