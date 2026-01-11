part of 'user_chat_bloc.dart';

enum UserChatStatus { initial, connecting, connected, disconnected, error }

class UserChatState extends Equatable {
  final UserChatStatus status;
  final List<ChatMessageModel> messages;
  final String? errorMessage;

  const UserChatState({
    this.status = UserChatStatus.initial,
    this.messages = const <ChatMessageModel>[],
    this.errorMessage,
  });

  UserChatState copyWith({
    UserChatStatus? status,
    List<ChatMessageModel>? messages,
    String? errorMessage,
  }) {
    return UserChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, messages, errorMessage];
}
