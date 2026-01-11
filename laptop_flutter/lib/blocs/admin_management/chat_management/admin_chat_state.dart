part of 'admin_chat_bloc.dart';

enum AdminChatStatus { initial, connecting, connected, disconnected, error }

class AdminChatState extends Equatable {
  final AdminChatStatus status;
  // Sử dụng Map để dễ dàng truy cập và cập nhật cuộc trò chuyện bằng userId
  final Map<String, AdminConversationModel> conversations;
  final Map<String, List<ChatMessageModel>>
      chatMessagesByConversation; // Lưu tin nhắn cho từng cuộc trò chuyện
  final String?
      selectedConversationUserId; // ID của user mà admin đang chat cùng
  final String? errorMessage;
  final Set<String> onlineUserIds; // Theo dõi user nào đang online

  const AdminChatState({
    this.status = AdminChatStatus.initial,
    this.conversations = const {},
    this.chatMessagesByConversation = const {},
    this.selectedConversationUserId,
    this.errorMessage,
    this.onlineUserIds = const {},
  });

  // Helper để lấy danh sách tin nhắn của cuộc trò chuyện đang được chọn
  List<ChatMessageModel> get currentSelectedChatMessages =>
      selectedConversationUserId != null
          ? (chatMessagesByConversation[selectedConversationUserId] ?? [])
          : [];

  // Helper để lấy thông tin conversation đang được chọn
  AdminConversationModel? get currentSelectedConversation =>
      selectedConversationUserId != null
          ? conversations[selectedConversationUserId]
          : null;

  AdminChatState copyWith({
    AdminChatStatus? status,
    Map<String, AdminConversationModel>? conversations,
    Map<String, List<ChatMessageModel>>? chatMessagesByConversation,
    String? selectedConversationUserId, // Cho phép null để bỏ chọn
    bool deselectConversation = false, // Thêm flag để bỏ chọn
    String? errorMessage,
    Set<String>? onlineUserIds,
  }) {
    return AdminChatState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      chatMessagesByConversation:
          chatMessagesByConversation ?? this.chatMessagesByConversation,
      selectedConversationUserId: deselectConversation
          ? null
          : (selectedConversationUserId ?? this.selectedConversationUserId),
      errorMessage: errorMessage ?? this.errorMessage,
      onlineUserIds: onlineUserIds ?? this.onlineUserIds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        conversations,
        chatMessagesByConversation,
        selectedConversationUserId,
        errorMessage,
        onlineUserIds,
      ];
}
