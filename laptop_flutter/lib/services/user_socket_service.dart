// lib/services/user_socket_service.dart
import 'package:flutter/material.dart';
import 'package:laptop_flutter/repositories/auth_repository.dart';
import 'package:laptop_flutter/services/local_notification_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class UserSocketService {
  IO.Socket? _socket;
  final AuthRepository _authRepository;
  bool _isConnected = false;

  // Sử dụng ValueNotifier để thông báo trạng thái kết nối nếu cần thiết cho UI
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);

  UserSocketService(this._authRepository);

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected && _socket?.connected == true) {
      print('UserSocketService: Already connected.');
      return;
    }

    final token = await _authRepository.getToken();
    if (token == null || token.isEmpty) {
      print('UserSocketService: No token found, cannot connect.');
      return;
    }

    print('UserSocketService: Attempting to connect...');
    try {
      _socket?.dispose(); // Dispose socket cũ nếu có
      _clearListeners();

      _socket = IO.io(
        _authRepository.baseUrl, // Lấy baseUrl từ AuthRepository
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        isConnectedNotifier.value = true;
        print(
            'UserSocketService: Connected to server. Socket ID: ${_socket?.id}');
        _registerEventListeners(); // Đăng ký các listener sau khi kết nối
      });

      _socket!.onConnectError((error) {
        _isConnected = false;
        isConnectedNotifier.value = false;
        print('UserSocketService: Connection Error: $error');
        // TODO: Có thể thêm logic retry hoặc thông báo lỗi cho người dùng
      });

      _socket!.onError((error) {
        print('UserSocketService: Socket Error: $error');
        // Xử lý lỗi chung của socket
      });

      _socket!.onDisconnect((reason) {
        _isConnected = false;
        isConnectedNotifier.value = false;
        print('UserSocketService: Disconnected from server. Reason: $reason');
        // TODO: Xử lý khi mất kết nối, ví dụ thử kết nối lại
      });

      _socket!.connect();
    } catch (e) {
      _isConnected = false;
      isConnectedNotifier.value = false;
      print('UserSocketService: Failed to initialize socket connection: $e');
    }
  }

  void _registerEventListeners() {
    if (_socket == null) return;

    // Lắng nghe sự kiện nhắc công nợ
    _socket!.on('payment_reminder', (data) {
      print('UserSocketService: Received payment_reminder: $data');
      if (data is Map<String, dynamic>) {
        try {
          final int? orderId = data['orderId'] as int?;
          final String? message = data['message'] as String?;
          final String? dueDate = data['dueDate'] as String?;

          if (orderId != null && message != null) {
            LocalNotificationService.showUserDebtReminderNotification(
              orderId: orderId,
              message: message,
              dueDate: dueDate,
            );
          } else {
            print('UserSocketService: Invalid payment_reminder data format.');
          }
        } catch (e) {
          print(
              'UserSocketService: Error parsing payment_reminder data: $e. Data: $data');
        }
      }
    });

    // Lắng nghe các sự kiện khác của user nếu cần
    // Ví dụ: _socket!.on('new_message_for_user', (data) { ... });
  }

  void _clearListeners() {
    _socket?.off('payment_reminder');
    // Xóa các listener khác nếu có
  }

  void disconnect() {
    print('UserSocketService: Disconnecting...');
    _socket?.disconnect();
    _clearListeners(); // Xóa listener khi ngắt kết nối
    _isConnected = false;
    isConnectedNotifier.value = false;
  }

  void dispose() {
    print('UserSocketService: Disposing...');
    _socket?.dispose();
    isConnectedNotifier.dispose();
  }

// Hàm gửi sự kiện (ví dụ cho chat nếu bạn muốn tách logic chat ra khỏi UserChatBloc)
// void sendMessage(String eventName, dynamic data) {
//   if (_isConnected && _socket?.connected == true) {
//     _socket!.emit(eventName, data);
//   } else {
//     print('UserSocketService: Cannot send message. Not connected.');
//   }
// }
}
