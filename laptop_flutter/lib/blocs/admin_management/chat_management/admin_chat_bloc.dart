import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Đảm bảo import LocalNotificationService
import '../../../../services/local_notification_service.dart';
import '../../../models/admin_conversation_model.dart';
import '../../../models/chat_message_model.dart';
import '../../auth/auth_bloc.dart'; // Để lấy token và userId của admin

part 'admin_chat_event.dart';
part 'admin_chat_state.dart';

class AdminChatBloc extends Bloc<AdminChatEvent, AdminChatState> {
  IO.Socket? _socket;
  final AuthBloc authBloc;

  String? get _currentAdminUserId {
    final authState = authBloc.state;
    if (authState is AuthAuthenticated && authState.user.role == 1) {
      // Đảm bảo là admin
      return authState.user.id.toString();
    }
    return null;
  }

  String? get _currentAdminName {
    final authState = authBloc.state;
    if (authState is AuthAuthenticated && authState.user.role == 1) {
      return authState.user.name;
    }
    return "Admin";
  }

  AdminChatBloc({required this.authBloc}) : super(const AdminChatState()) {
    on<ConnectAdminChatServer>(_onConnectAdminChatServer);
    on<SendAdminChatMessage>(_onSendAdminChatMessage);
    on<_ReceivedMessageFromUser>(_onReceivedMessageFromUser);
    on<_UserConnectedForChat>(_onUserConnectedForChat);
    on<_UserDisconnectedFromChat>(_onUserDisconnectedFromChat);
    on<SelectConversation>(_onSelectConversation);
    on<DisconnectAdminChatServer>(_onDisconnectAdminChatServer);
    on<_AdminChatConnectionError>(_onAdminChatConnectionError);
    on<RefreshAdminConversations>(_onRefreshAdminConversations);
    on<_AdminChatConnected>(_onAdminChatConnected);
    on<_AdminChatDisconnected>(_onAdminChatDisconnected);
    on<_ShowConsultationNotification>(_onShowConsultationNotification);
  }

  void _clearSocketListeners() {
    _socket?.off('connect');
    _socket?.off('disconnect');
    _socket?.off('error');
    _socket?.off('connect_error');
    _socket?.off(
        'receive_message'); // Admin sẽ nhận tin nhắn từ user qua event này
    _socket
        ?.off('user_connected_chat'); // Event từ server báo user mới vào chat
    _socket
        ?.off('user_disconnected_chat'); // Event từ server báo user thoát chat
    _socket?.off('new_consultation_request_notification');
  }

  void _onConnectAdminChatServer(
      ConnectAdminChatServer event, Emitter<AdminChatState> emit) {
    if (_socket?.connected ?? false) {
      if (!emit.isDone && !isClosed) {
        // Vẫn cần kiểm tra trước khi emit trực tiếp
        emit(state.copyWith(
            status: AdminChatStatus.connected, errorMessage: null));
      }
      return;
    }
    if (state.status == AdminChatStatus.connecting) return;

    final String? token = event.token;
    final adminId = _currentAdminUserId;

    if (token == null || token.isEmpty || adminId == null) {
      emit(state.copyWith(
          status: AdminChatStatus.error,
          errorMessage: "Xác thực Admin thất bại hoặc token không hợp lệ."));
      return;
    }

    emit(
        state.copyWith(status: AdminChatStatus.connecting, errorMessage: null));

    try {
      _socket?.dispose();
      _clearSocketListeners();

      _socket = IO.io(
          authBloc.authRepository.baseUrl,
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .setAuth({'token': token})
              .build());

      _socket!.onConnect((_) {
        if (!isClosed) {
          add(const _AdminChatConnected());
        }
      });

      _socket!.onConnectError((error) {
        print('AdminChatBloc: Connection Error: $error');
        if (!isClosed) {
          // isClosed là đủ cho việc add event
          add(_AdminChatConnectionError('Lỗi kết nối Admin: $error'));
        }
      });
      _socket!.onError((error) {
        print('AdminChatBloc: Socket Error: $error');
        if (!isClosed) {
          add(_AdminChatConnectionError('Lỗi Socket Admin: $error'));
        }
      });

      _socket!.onDisconnect((reason) {
        print('AdminChatBloc: Disconnected from chat server. Reason: $reason');
        if (!isClosed) {
          add(_AdminChatDisconnected(reason?.toString()));
        }
      });

      _socket!.on('admin_payment_reminder_alert', (data) {
        print('AdminChatBloc: Received admin_payment_reminder_alert: $data');
        try {
          if (data is Map<String, dynamic> && !isClosed) {
            final String? orderId = data['orderId']?.toString();
            final String? userName = data['userName'] as String?;
            final String? message =
                data['message'] as String?; // Nội dung thông báo từ backend

            if (orderId != null && userName != null && message != null) {
              // Sử dụng GlobalKey<NavigatorState> navigatorKey đã truyền vào LocalNotificationService
              // Hoặc bạn có thể tạo một hàm riêng trong LocalNotificationService cho loại thông báo này
              LocalNotificationService.showConsultationNotification(
                // Có thể tạo hàm riêng
                userName: "Nhắc nhở KH: $userName", // Tiêu đề thông báo
                messageText: message, // Nội dung chính
                conversationId:
                    "credit_order_$orderId", // Payload để xử lý khi nhấn, ví dụ: điều hướng đến chi tiết đơn công nợ
              );

              // Có thể emit một state để cập nhật UI nếu cần (ví dụ: hiển thị badge thông báo)
              // add(_AdminReceivedPaymentReminderAlert(orderId: orderId, userName: userName, message: message));
            }
          }
        } catch (e) {
          print(
              "AdminChatBloc: Error parsing admin_payment_reminder_alert: $e");
        }
      });

      // Lắng nghe tin nhắn từ user (server sẽ gửi event 'receive_message')
      _socket!.on('receive_message', (data) {
        print('AdminChatBloc: Received message from user: $data');
        try {
          // Admin luôn là người nhận, nên isMine luôn là false khi parse
          // conversationId sẽ là senderId của user
          final message = ChatMessageModel.fromJson(
              data as Map<String, dynamic>,
              _currentAdminUserId!); // currentAdminId để xác định tin nhắn admin gửi (nếu server có gửi lại)
          add(_ReceivedMessageFromUser(message));
        } catch (e) {
          print("AdminChatBloc: Error parsing received message from user: $e");
        }
      });

      // Lắng nghe khi có user mới kết nối để chat
      _socket!.on('user_connected_chat', (data) {
        print('AdminChatBloc: User connected for chat: $data');
        try {
          final userId = data['userId'].toString();
          final userName = data['userName'] as String;
          add(_UserConnectedForChat(userId: userId, userName: userName));
        } catch (e) {
          print("AdminChatBloc: Error parsing user_connected_chat: $e");
        }
      });

      // Lắng nghe khi user ngắt kết nối chat
      _socket!.on('user_disconnected_chat', (data) {
        print('AdminChatBloc: User disconnected from chat: $data');
        try {
          final userId = data['userId'].toString();
          add(_UserDisconnectedFromChat(userId));
        } catch (e) {
          print("AdminChatBloc: Error parsing user_disconnected_chat: $e");
        }
      });
      _socket!.on('new_consultation_request_notification', (data) {
        print(
            'AdminChatBloc: Received new_consultation_request_notification: $data');
        try {
          if (data is Map<String, dynamic>) {
            final String? userName = data['userName'];
            final String? messageText = data['messageText'];
            final String? conversationId = data['conversationId'];

            if (userName != null &&
                messageText != null &&
                conversationId != null &&
                !isClosed) {
              // Thêm một event mới để xử lý việc hiển thị thông báo
              add(_ShowConsultationNotification(
                userName: userName,
                messageText: messageText,
                conversationId: conversationId,
              ));
            }
          }
        } catch (e) {
          print(
              "AdminChatBloc: Error parsing new_consultation_request_notification: $e");
        }
      });
      _socket!.connect();
    } catch (e) {
      print('AdminChatBloc: Failed to initialize socket connection: $e');
      emit(state.copyWith(
          status: AdminChatStatus.error,
          errorMessage: 'Không thể khởi tạo kết nối Admin: $e'));
    }
  }

  void _onShowConsultationNotification(
      _ShowConsultationNotification event, Emitter<AdminChatState> emit) {
    // Gọi service để hiển thị thông báo
    LocalNotificationService.showConsultationNotification(
      userName: event.userName,
      messageText: event.messageText,
      conversationId: event.conversationId,
    );
    // Bạn có thể emit một state mới ở đây nếu cần cập nhật UI nào đó liên quan đến việc nhận thông báo
    // Ví dụ: tăng badge count trên icon chat, v.v.
    // Hiện tại, chúng ta chỉ hiển thị thông báo.
  }

  void _onAdminChatConnected(
      _AdminChatConnected event, Emitter<AdminChatState> emit) {
    if (emit.isDone || isClosed) return;
    print("AdminChatBloc: Processing _AdminChatConnected event.");
    emit(state.copyWith(status: AdminChatStatus.connected, errorMessage: null));
    // Tại đây, bạn có thể add một event khác để yêu cầu tải dữ liệu ban đầu nếu cần
    // ví dụ: add(LoadInitialAdminChatData());
  }

  void _onAdminChatDisconnected(
      _AdminChatDisconnected event, Emitter<AdminChatState> emit) {
    if (emit.isDone || isClosed) return;
    print(
        "AdminChatBloc: Processing _AdminChatDisconnected event. Reason: ${event.reason}");
    // Khi ngắt kết nối, có thể bạn muốn xóa danh sách cuộc trò chuyện hoặc giữ lại
    // tùy theo logic ứng dụng. Ở đây tạm thời chỉ đổi status và xóa online users.
    emit(state.copyWith(
        status: AdminChatStatus.disconnected,
        onlineUserIds: {}, // Xóa danh sách user online
        // conversations: {}, // Cân nhắc có nên xóa conversations không
        // chatMessagesByConversation: {}, // Cân nhắc có nên xóa messages không
        selectedConversationUserId: null, // Bỏ chọn conversation
        errorMessage: null));
  }

  void _onSendAdminChatMessage(
      SendAdminChatMessage event, Emitter<AdminChatState> emit) {
    final adminId = _currentAdminUserId;
    if (_socket?.connected == true && adminId != null) {
      final messageData = {
        'text': event.text,
        'recipientId': event.recipientUserId, // Gửi cho user cụ thể
      };
      _socket!.emit('send_message', messageData);

      final sentMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ID tạm thời
        senderId: adminId,
        senderName: _currentAdminName ?? "Hỗ trợ", // Tên của admin
        text: event.text,
        timestamp: DateTime.now(),
        isMine: true, // Tin nhắn này là của admin (client hiện tại)
        conversationId: event.recipientUserId,
      );

      // Cập nhật tin nhắn vào đúng cuộc trò chuyện
      final Map<String, List<ChatMessageModel>> updatedMessagesByConversation =
          Map.from(state.chatMessagesByConversation);
      final List<ChatMessageModel> conversationMessages =
          List.from(updatedMessagesByConversation[event.recipientUserId] ?? []);
      conversationMessages.add(sentMessage);
      updatedMessagesByConversation[event.recipientUserId] =
          conversationMessages
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Cập nhật lastMessage cho conversation
      final Map<String, AdminConversationModel> updatedConversations =
          Map.from(state.conversations);
      if (updatedConversations.containsKey(event.recipientUserId)) {
        updatedConversations[event.recipientUserId] =
            updatedConversations[event.recipientUserId]!
                .copyWith(lastMessage: sentMessage);
      }

      emit(state.copyWith(
          chatMessagesByConversation: updatedMessagesByConversation,
          conversations: updatedConversations));
    } else {
      emit(state.copyWith(
          status: AdminChatStatus.error,
          errorMessage: 'Admin chưa kết nối để gửi tin nhắn.'));
    }
  }

  void _onReceivedMessageFromUser(
      _ReceivedMessageFromUser event, Emitter<AdminChatState> emit) {
    final message = event.message;
    final conversationId = message.conversationId ?? message.senderId;
    // Cập nhật danh sách tin nhắn cho cuộc trò chuyện này
    final Map<String, List<ChatMessageModel>> updatedMessagesByConversation =
        Map.from(state.chatMessagesByConversation);
    final List<ChatMessageModel> conversationMessages =
        List.from(updatedMessagesByConversation[conversationId] ?? []);

    // Kiểm tra tin nhắn đã tồn tại chưa (dựa trên id nếu có, hoặc nội dung + thời gian)
    bool messageExists = conversationMessages.any((m) =>
        m.id != null && m.id == message.id ||
        (m.text == message.text &&
            m.timestamp == message.timestamp &&
            m.senderId == message.senderId));

    if (!messageExists) {
      conversationMessages.add(message);
      updatedMessagesByConversation[conversationId] = conversationMessages
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    // Cập nhật hoặc tạo mới cuộc trò chuyện trong danh sách conversations
    final Map<String, AdminConversationModel> updatedConversations =
        Map.from(state.conversations);
    if (updatedConversations.containsKey(conversationId)) {
      updatedConversations[conversationId] =
          updatedConversations[conversationId]!.copyWith(
              lastMessage: message,
              // Tăng unreadCount nếu admin không đang xem cuộc trò chuyện này
              unreadCount: state.selectedConversationUserId == conversationId
                  ? 0
                  : (updatedConversations[conversationId]!.unreadCount + 1),
              isOnline: state.onlineUserIds
                  .contains(conversationId) // Giữ trạng thái online
              );
    } else {
      // Tạo mới cuộc trò chuyện nếu chưa có (thường khi user gửi tin nhắn đầu tiên)
      updatedConversations[conversationId] = AdminConversationModel(
        userId: conversationId,
        userName: message.senderName, // Lấy tên từ tin nhắn đầu tiên của user
        lastMessage: message,
        unreadCount: 1,
        isOnline: true, // User vừa gửi tin nhắn thì chắc chắn online
      );
    }

    // Sắp xếp lại danh sách cuộc trò chuyện để cuộc trò chuyện có tin nhắn mới nhất lên đầu
    final sortedConversations =
        Map.fromEntries(updatedConversations.entries.toList()
          ..sort((e1, e2) {
            final t1 = e1.value.lastMessage?.timestamp;
            final t2 = e2.value.lastMessage?.timestamp;
            if (t1 == null && t2 == null) return 0;
            if (t1 == null) return 1; // nulls last
            if (t2 == null) return -1; // nulls last
            return t2.compareTo(t1); // Mới nhất lên đầu
          }));

    emit(state.copyWith(
      conversations: sortedConversations,
      chatMessagesByConversation: updatedMessagesByConversation,
    ));
  }

  void _onUserConnectedForChat(
      _UserConnectedForChat event, Emitter<AdminChatState> emit) {
    final Map<String, AdminConversationModel> updatedConversations =
        Map.from(state.conversations);
    final Set<String> updatedOnlineUserIds = Set.from(state.onlineUserIds)
      ..add(event.userId);

    if (!updatedConversations.containsKey(event.userId)) {
      updatedConversations[event.userId] = AdminConversationModel(
        userId: event.userId,
        userName: event.userName,
        isOnline: true,
      );
    } else {
      updatedConversations[event.userId] =
          updatedConversations[event.userId]!.copyWith(isOnline: true);
    }
    emit(state.copyWith(
        conversations: updatedConversations,
        onlineUserIds: updatedOnlineUserIds));
  }

  void _onUserDisconnectedFromChat(
      _UserDisconnectedFromChat event, Emitter<AdminChatState> emit) {
    final Map<String, AdminConversationModel> updatedConversations =
        Map.from(state.conversations);
    final Set<String> updatedOnlineUserIds = Set.from(state.onlineUserIds)
      ..remove(event.userId);

    if (updatedConversations.containsKey(event.userId)) {
      updatedConversations[event.userId] =
          updatedConversations[event.userId]!.copyWith(isOnline: false);
    }
    emit(state.copyWith(
        conversations: updatedConversations,
        onlineUserIds: updatedOnlineUserIds));
  }

  void _onSelectConversation(
      SelectConversation event, Emitter<AdminChatState> emit) {
    if (event.userId == null) {
      // Bỏ chọn
      emit(state.copyWith(
          selectedConversationUserId: null, deselectConversation: true));
    } else {
      final Map<String, AdminConversationModel> updatedConversations =
          Map.from(state.conversations);
      // Reset unreadCount khi admin mở cuộc trò chuyện
      if (updatedConversations.containsKey(event.userId)) {
        updatedConversations[event.userId!] =
            updatedConversations[event.userId!]!.copyWith(unreadCount: 0);
      }
      emit(state.copyWith(
          selectedConversationUserId: event.userId,
          conversations: updatedConversations));
      // TODO: Có thể thêm logic để fetch lịch sử tin nhắn của conversation này từ server nếu cần
      // _socket?.emit('admin_load_conversation_history', {'userId': event.userId});
    }
  }

  void _onRefreshAdminConversations(
      RefreshAdminConversations event, Emitter<AdminChatState> emit) {
    // Logic để làm mới danh sách cuộc trò chuyện, ví dụ, yêu cầu lại từ server
    // Điều này hữu ích nếu trạng thái có thể bị lỗi thời
    if (_socket?.connected == true) {
      // _socket.emit('admin_request_initial_data'); // Hoặc một event tương tự
      print("AdminChatBloc: Refreshing conversations (placeholder)");
    }
  }

  void _onAdminChatConnectionError(
      _AdminChatConnectionError event, Emitter<AdminChatState> emit) {
    emit(state.copyWith(
        status: AdminChatStatus.error, errorMessage: event.errorMessage));
  }

  void _onDisconnectAdminChatServer(
      DisconnectAdminChatServer event, Emitter<AdminChatState> emit) {
    print('AdminChatBloc: Disconnecting from server explicitly via event.');
    _socket?.disconnect();
  }

  @override
  Future<void> close() {
    print('AdminChatBloc: Closing and disposing socket.');
    _clearSocketListeners();
    _socket?.dispose();
    return super.close();
  }
}
