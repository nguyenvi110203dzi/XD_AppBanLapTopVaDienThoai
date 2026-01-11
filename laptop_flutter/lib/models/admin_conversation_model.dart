// lib/models/admin_conversation_model.dart
import 'package:equatable/equatable.dart';

import 'chat_message_model.dart'; // Model tin nhắn đã tạo

class AdminConversationModel extends Equatable {
  final String userId; // ID của khách hàng
  final String userName;
  final String? userAvatar;
  final ChatMessageModel?
      lastMessage; // Tin nhắn cuối cùng trong cuộc trò chuyện
  final int unreadCount; // Số tin nhắn chưa đọc từ user này (tùy chọn)
  final bool isOnline; // User này có đang online không

  const AdminConversationModel({
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.lastMessage,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  AdminConversationModel copyWith({
    String? userName,
    String? userAvatar,
    ChatMessageModel? lastMessage,
    int? unreadCount,
    bool? isOnline,
  }) {
    return AdminConversationModel(
      userId: userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props =>
      [userId, userName, userAvatar, lastMessage, unreadCount, isOnline];
}
