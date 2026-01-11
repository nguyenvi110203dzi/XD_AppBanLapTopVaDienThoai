// lib/blocs/chat/user_chat_bloc.dart (Ví dụ sửa lỗi)
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../models/chat_message_model.dart';
import '../auth/auth_bloc.dart';

part 'user_chat_event.dart'; // Giả sử đã có
part 'user_chat_state.dart'; // Giả sử đã có

class UserChatBloc extends Bloc<UserChatEvent, UserChatState> {
  IO.Socket? _socket;
  final AuthBloc authBloc;

  String? get _currentUserId {
    final authState = authBloc.state;
    if (authState is AuthAuthenticated) {
      return authState.user.id.toString();
    }
    return null;
  }

  String get _currentUserName {
    // Lấy tên user để hiển thị "Bạn"
    final authState = authBloc.state;
    if (authState is AuthAuthenticated) {
      return authState.user.name;
    }
    return "Bạn";
  }

  UserChatBloc({required this.authBloc}) : super(const UserChatState()) {
    on<ConnectUserChatServer>(_onConnectUserChatServer);
    on<SendUserChatMessage>(_onSendUserChatMessage);
    on<_ReceivedUserChatMessage>(_onReceivedUserChatMessage);
    on<_UserChatConnectionError>(_onUserChatConnectionError);
    on<_UserChatSocketDisconnected>(_onUserChatSocketDisconnected); // Event mới
    on<DisconnectUserChatServer>(_onDisconnectUserChatServer);
  }

  void _clearSocketListeners() {
    _socket?.off('connect');
    _socket?.off('disconnect');
    _socket?.off('connect_error');
    _socket?.off('error');
    _socket?.off('receive_message');
    _socket?.off('system_message');
    _socket?.off('message_saved_confirmation'); // Nếu bạn dùng event này
  }

  void _onConnectUserChatServer(
      ConnectUserChatServer event, Emitter<UserChatState> emit) {
    if (_socket?.connected ?? false) {
      if (!emit.isDone) emit(state.copyWith(status: UserChatStatus.connected));
      return;
    }
    if (state.status == UserChatStatus.connecting) return;

    final String? token = event.token;
    if (token == null || token.isEmpty) {
      if (!emit.isDone)
        emit(state.copyWith(
            status: UserChatStatus.error,
            errorMessage: "Token không hợp lệ để kết nối chat."));
      return;
    }

    if (!emit.isDone)
      emit(state.copyWith(
          status: UserChatStatus.connecting, errorMessage: null));

    try {
      _socket?.dispose(); // Đảm bảo socket cũ được dọn dẹp
      _clearSocketListeners();

      _socket = IO.io(
          authBloc.authRepository.baseUrl, // Lấy baseUrl từ AuthRepository
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .setAuth({'token': token})
              .build());

      _socket!.onConnect((_) {
        print(
            'UserChatBloc: Connected to chat server. Socket ID: ${_socket?.id}');
        if (!isClosed && !emit.isDone) {
          emit(state.copyWith(
              status: UserChatStatus.connected, errorMessage: null));
        }
      });

      _socket!.onConnectError((error) {
        print('UserChatBloc: Connection Error: $error');
        if (!isClosed) add(_UserChatConnectionError('Lỗi kết nối: $error'));
      });

      _socket!.onError((error) {
        print('UserChatBloc: Socket Error: $error');
        if (!isClosed) add(_UserChatConnectionError('Lỗi Socket: $error'));
      });

      _socket!.onDisconnect((reason) {
        print('UserChatBloc: Disconnected from chat server. Reason: $reason');
        if (!isClosed) add(_UserChatSocketDisconnected(reason?.toString()));
      });

      _socket!.on('receive_message', (data) {
        print('UserChatBloc: Received message: $data');
        try {
          final currentUserId = _currentUserId;
          if (currentUserId != null) {
            final message = ChatMessageModel.fromJson(
                data as Map<String, dynamic>, currentUserId);
            add(_ReceivedUserChatMessage(message));
          } else {
            if (!isClosed)
              add(_UserChatConnectionError(
                  'Lỗi xác thực người dùng khi nhận tin nhắn.'));
          }
        } catch (e) {
          print("UserChatBloc: Error parsing received message: $e");
          if (!isClosed)
            add(_UserChatConnectionError('Lỗi xử lý tin nhắn nhận được.'));
        }
      });

      _socket!.on('system_message', (data) {
        print('UserChatBloc: Received system message: $data');
        try {
          final message = ChatMessageModel(
            id: data['id'] as String? ??
                'system_${DateTime.now().millisecondsSinceEpoch}',
            senderId: 'SYSTEM',
            senderName: data['senderName'] as String? ?? 'Hệ thống',
            text: data['text'] as String,
            timestamp: DateTime.parse(data['timestamp'] as String),
            isMine: false,
          );
          if (!isClosed) add(_ReceivedUserChatMessage(message));
        } catch (e) {
          print("UserChatBloc: Error parsing system message: $e");
        }
      });

      _socket!.on('message_saved_confirmation', (data) {
        print('UserChatBloc: Received message saved confirmation: $data');
        try {
          final savedMessageData = data['savedMessage'] as Map<String, dynamic>;
          final tempId = data['tempId'] as String?;
          final currentUserId = _currentUserId;

          if (currentUserId != null) {
            final confirmedMessage =
                ChatMessageModel.fromJson(savedMessageData, currentUserId);
            if (!isClosed)
              add(_MessageSuccessfullySent(
                  tempId: tempId, confirmedMessage: confirmedMessage));
          }
        } catch (e) {
          print(
              'UserChatBloc: Error processing message_saved_confirmation: $e');
        }
      });

      _socket!.connect();
    } catch (e) {
      print('UserChatBloc: Failed to initialize socket connection: $e');
      if (!emit.isDone)
        emit(state.copyWith(
            status: UserChatStatus.error,
            errorMessage: 'Không thể khởi tạo kết nối: $e'));
    }
  }

  void _onSendUserChatMessage(
      SendUserChatMessage event, Emitter<UserChatState> emit) {
    if (emit.isDone) return;
    final currentUserId = _currentUserId;
    if (_socket?.connected == true && currentUserId != null) {
      final tempId =
          'temp_${DateTime.now().millisecondsSinceEpoch}'; // Tạo ID tạm thời
      final messageData = {
        'text': event.text,
        'tempId': tempId // Gửi tempId lên server
      };
      _socket!.emit('send_message', messageData);

      final sentMessage = ChatMessageModel(
        id: tempId, // Sử dụng tempId
        senderId: currentUserId,
        senderName: _currentUserName, // Lấy tên user
        text: event.text,
        timestamp: DateTime.now(),
        isMine: true,
        // Thêm trạng thái sending nếu bạn có model hỗ trợ
      );
      emit(state.copyWith(
          messages: List.from(state.messages)..add(sentMessage)));
    } else {
      // ... xử lý lỗi
    }
  }

  // Event mới để xử lý khi tin nhắn được server xác nhận đã lưu
  Future<void> _onMessageSuccessfullySent(
      _MessageSuccessfullySent event, Emitter<UserChatState> emit) async {
    if (emit.isDone) return;
    final List<ChatMessageModel> updatedMessages = List.from(state.messages);
    final int messageIndex =
        updatedMessages.indexWhere((msg) => msg.id == event.tempId);

    if (messageIndex != -1) {
      updatedMessages[messageIndex] = event
          .confirmedMessage; // Thay thế tin nhắn tạm bằng tin nhắn đã xác nhận
      print(
          "UserChatBloc: Message ${event.tempId} confirmed with ID ${event.confirmedMessage.id}");
    } else {
      // Nếu không tìm thấy tempId, có thể là tin nhắn từ session khác hoặc lỗi, thêm vào nếu chưa có
      if (!updatedMessages.any((msg) => msg.id == event.confirmedMessage.id)) {
        updatedMessages.add(event.confirmedMessage);
      }
    }
    updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    emit(state.copyWith(messages: updatedMessages));
  }

  void _onReceivedUserChatMessage(
      _ReceivedUserChatMessage event, Emitter<UserChatState> emit) {
    if (emit.isDone || isClosed) return;
    print(
        "UserChatBloc: Processing _ReceivedUserChatMessage with message from ${event.message.senderName}: ${event.message.text}");
    final List<ChatMessageModel> updatedMessages = List.from(state.messages);

    // Chỉ thêm tin nhắn nếu nó không phải của user hiện tại (vì tin nhắn của user hiện tại đã được thêm ở _onSendUserChatMessage)
    // Và cũng kiểm tra xem tin nhắn này (dựa trên ID thật từ server) đã tồn tại chưa (để tránh trùng lặp từ event message_saved_confirmation)
    if (event.message.senderId != _currentUserId &&
        !updatedMessages.any((m) => m.id == event.message.id && m.id != null)) {
      updatedMessages.add(event.message);
      print(
          "UserChatBloc: Added message from other user or system: ${event.message.id}");
    } else if (event.message.senderId == _currentUserId) {
      print(
          "UserChatBloc: Ignoring own message received via 'receive_message' (already handled by confirmation or optimistic update). ID: ${event.message.id}");
    }

    updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    emit(state.copyWith(
        messages: updatedMessages,
        status: UserChatStatus.connected,
        errorMessage: null));
  }

  void _onUserChatSocketDisconnected(
      _UserChatSocketDisconnected event, Emitter<UserChatState> emit) {
    if (emit.isDone || isClosed) return;
    emit(state.copyWith(
        status: UserChatStatus.disconnected, messages: [], errorMessage: null));
  }

  void _onUserChatConnectionError(
      _UserChatConnectionError event, Emitter<UserChatState> emit) {
    if (emit.isDone || isClosed) return;
    emit(state.copyWith(
        status: UserChatStatus.error, errorMessage: event.errorMessage));
  }

  void _onDisconnectUserChatServer(
      DisconnectUserChatServer event, Emitter<UserChatState> emit) {
    print(
        'UserChatBloc: Disconnecting from server explicitly via DisconnectUserChatServer event.');
    _socket?.disconnect();
    // Trạng thái sẽ được cập nhật bởi listener _socket!.onDisconnect -> _UserChatSocketDisconnected
  }

  @override
  Future<void> close() {
    print('UserChatBloc: Closing and disposing socket.');
    _clearSocketListeners();
    _socket?.dispose();
    return super.close();
  }
}

// Thêm event này vào user_chat_event.dart
// part of 'user_chat_bloc.dart';
// class _MessageSuccessfullySent extends UserChatEvent {
//   final String? tempId;
//   final ChatMessageModel confirmedMessage;
//   const _MessageSuccessfullySent({this.tempId, required this.confirmedMessage});
//   @override
//   List<Object?> get props => [tempId, confirmedMessage];
// }
