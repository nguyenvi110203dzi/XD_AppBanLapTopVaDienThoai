part of 'admin_chat_bloc.dart';

abstract class AdminChatEvent extends Equatable {
  const AdminChatEvent();
  @override
  List<Object?> get props => [];
}

class ConnectAdminChatServer extends AdminChatEvent {
  final String token;
  const ConnectAdminChatServer(this.token);
  @override
  List<Object?> get props => [token];
}

// Event khi admin gửi tin nhắn cho một user cụ thể
class SendAdminChatMessage extends AdminChatEvent {
  final String text;
  final String recipientUserId; // ID của user nhận tin nhắn
  const SendAdminChatMessage(
      {required this.text, required this.recipientUserId});
  @override
  List<Object?> get props => [text, recipientUserId];
}

// Event nội bộ khi admin nhận được tin nhắn từ một user
class _ReceivedMessageFromUser extends AdminChatEvent {
  final ChatMessageModel message;
  // conversationId (chính là senderId của user) đã có trong message.conversationId
  const _ReceivedMessageFromUser(this.message);
  @override
  List<Object?> get props => [message];
}

// Event nội bộ khi có user mới kết nối vào chat
class _UserConnectedForChat extends AdminChatEvent {
  final String userId;
  final String userName;
  const _UserConnectedForChat({required this.userId, required this.userName});
  @override
  List<Object?> get props => [userId, userName];
}

// Event nội bộ khi user ngắt kết nối khỏi chat
class _UserDisconnectedFromChat extends AdminChatEvent {
  final String userId;
  const _UserDisconnectedFromChat(this.userId);
  @override
  List<Object?> get props => [userId];
}

// Event khi admin chọn một cuộc trò chuyện để xem chi tiết
class SelectConversation extends AdminChatEvent {
  final String? userId; // null để bỏ chọn
  const SelectConversation(this.userId);
  @override
  List<Object?> get props => [userId];
}

// Event để load lại danh sách các cuộc trò chuyện (tùy chọn, nếu cần refresh)
class RefreshAdminConversations extends AdminChatEvent {}

class DisconnectAdminChatServer extends AdminChatEvent {}

class _AdminChatConnectionError extends AdminChatEvent {
  final String errorMessage;
  const _AdminChatConnectionError(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class _AdminChatConnected extends AdminChatEvent {
  // Khi kết nối socket thành công
  const _AdminChatConnected();
  @override
  List<Object?> get props => [];
}

class _AdminChatDisconnected extends AdminChatEvent {
  // Khi socket bị ngắt kết nối
  final String? reason;
  const _AdminChatDisconnected(this.reason);
  @override
  List<Object?> get props => [reason];
}

class _ShowConsultationNotification extends AdminChatEvent {
  final String userName;
  final String messageText;
  final String conversationId;

  const _ShowConsultationNotification({
    required this.userName,
    required this.messageText,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [userName, messageText, conversationId];
}
