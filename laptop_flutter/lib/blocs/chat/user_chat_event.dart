part of 'user_chat_bloc.dart'; // Sử dụng part of để liên kết file

abstract class UserChatEvent extends Equatable {
  const UserChatEvent();

  @override
  List<Object?> get props => [];
}

class ConnectUserChatServer extends UserChatEvent {
  final String token;
  const ConnectUserChatServer(this.token);

  @override
  List<Object?> get props => [token];
}

class SendUserChatMessage extends UserChatEvent {
  final String text;
  const SendUserChatMessage({required this.text});

  @override
  List<Object?> get props => [text];
}

// Event này được BLoC tự add khi nhận tin nhắn từ socket
class _ReceivedUserChatMessage extends UserChatEvent {
  final ChatMessageModel message;
  const _ReceivedUserChatMessage(this.message);

  @override
  List<Object?> get props => [message];
}

// Event này được BLoC tự add khi có lỗi từ socket
class _UserChatConnectionError extends UserChatEvent {
  final String errorMessage;
  const _UserChatConnectionError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class DisconnectUserChatServer extends UserChatEvent {}

class _UserChatSocketDisconnected extends UserChatEvent {
  // Event mới
  final String? reason;
  const _UserChatSocketDisconnected(this.reason);
  @override
  List<Object?> get props => [reason];
}

class _MessageSuccessfullySent extends UserChatEvent {
  final String? tempId;
  final ChatMessageModel confirmedMessage;
  const _MessageSuccessfullySent({this.tempId, required this.confirmedMessage});
  @override
  List<Object?> get props => [tempId, confirmedMessage];
}
