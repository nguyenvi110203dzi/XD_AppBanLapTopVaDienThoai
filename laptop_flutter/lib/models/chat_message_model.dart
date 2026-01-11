// lib/models/chat_message_model.dart
class ChatMessageModel {
  final String? id; // ID tin nhắn (từ server hoặc client tự generate)
  final String senderId;
  final String senderName; // Tên người gửi để hiển thị
  final String text;
  final DateTime timestamp;
  final bool isMine; // Để UI biết hiển thị bên trái hay phải
  final String? conversationId; // Dùng cho admin để quản lý các cuộc chat

  ChatMessageModel({
    this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMine,
    this.conversationId,
  });

  factory ChatMessageModel.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    final dynamic jsonId = json['id'];
    final dynamic jsonSenderId =
        json['senderId']; // Server gửi senderId là String
    final dynamic jsonConversationId = json['conversationId'];
    return ChatMessageModel(
      id: json['id']?.toString(),
      senderId: json['senderId'].toString(),
      senderName: json['senderName'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isMine: json['isMine'] ?? false, // Mặc định false khi nhận từ server
      conversationId: json['conversationId'],
    );
  }
}
