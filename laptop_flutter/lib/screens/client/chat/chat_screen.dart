// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Thêm thư viện này vào pubspec.yaml nếu chưa có: intl: ^any

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/chat/user_chat_bloc.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/user.dart';
import '../../../repositories/auth_repository.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late UserChatBloc _userChatBloc;
  String? _currentUserId;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _userChatBloc = BlocProvider.of<UserChatBloc>(context); // Lấy BLoC
    final authState = BlocProvider.of<AuthBloc>(context).state;
    final authRepository = RepositoryProvider.of<AuthRepository>(context);

    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.id.toString();
      _currentUser = authState.user;
      authRepository.getToken().then((token) {
        if (token != null && token.isNotEmpty) {
          if (mounted) {
            // Quan trọng: Kiểm tra mounted
            _userChatBloc.add(ConnectUserChatServer(token));
          }
        } else {
          _handleAuthError("Không tìm thấy token...");
        }
      }).catchError((error) {
        _handleAuthError("Lỗi khi lấy token...");
      });
    } else {
      _handleAuthError("Người dùng chưa được xác thực...");
    }
  }

  void _handleAuthError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Kiểm tra xem có thể pop không, nếu không thì không làm gì để tránh lỗi
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Quyết định xem có ngắt kết nối khi rời màn hình không.
    // Để đơn giản, hiện tại sẽ ngắt kết nối.
    // Trong ứng dụng thực tế, có thể bạn muốn giữ kết nối.
    _userChatBloc.add(DisconnectUserChatServer());
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _userChatBloc
          .add(SendUserChatMessage(text: _messageController.text.trim()));
      _messageController.clear();
      // Không cần cuộn ở đây nữa vì BlocConsumer sẽ làm khi state messages thay đổi
    }
  }

  void _scrollToBottom() {
    // Cuộn xuống cuối danh sách tin nhắn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ trợ Khách hàng'),
        actions: [
          // Nút để test disconnect (có thể bỏ đi sau)
          IconButton(
            icon: Icon(Icons.cloud_off),
            onPressed: () => _userChatBloc.add(DisconnectUserChatServer()),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<UserChatBloc, UserChatState>(
              bloc: _userChatBloc, // Chỉ định bloc để lắng nghe
              listener: (context, state) {
                if (state.status == UserChatStatus.error &&
                    state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(state.errorMessage!),
                        backgroundColor: Colors.red),
                  );
                }
                // Cuộn xuống khi có tin nhắn mới hoặc khi kết nối thành công và có tin nhắn
                if (state.messages.isNotEmpty) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state.status == UserChatStatus.connecting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == UserChatStatus.disconnected) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Đã ngắt kết nối với máy chủ chat.'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            final authState =
                                BlocProvider.of<AuthBloc>(context).state;
                            final authRepository =
                                RepositoryProvider.of<AuthRepository>(context);

                            if (authState is AuthAuthenticated) {
                              // Lấy token từ AuthRepository
                              authRepository.getToken().then((tokenFromRepo) {
                                if (tokenFromRepo != null &&
                                    tokenFromRepo.isNotEmpty) {
                                  if (mounted) {
                                    _userChatBloc.add(
                                        ConnectUserChatServer(tokenFromRepo));
                                  }
                                } else {
                                  _handleAuthError(
                                      "Không tìm thấy token để kết nối lại.");
                                }
                              }).catchError((error) {
                                _handleAuthError(
                                    "Lỗi khi lấy token để kết nối lại: $error");
                              });
                            } else {
                              // Nếu không còn trong trạng thái AuthAuthenticated,
                              // có thể người dùng đã bị logout ở đâu đó.
                              _handleAuthError(
                                  "Người dùng chưa được xác thực để kết nối lại.");
                            }
                          },
                          child: const Text('Kết nối lại'),
                        )
                      ],
                    ),
                  );
                }
                if (state.status == UserChatStatus.connecting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == UserChatStatus.connected ||
                    state.status == UserChatStatus.initial &&
                        state.messages.isNotEmpty) {
                  if (state.messages.isEmpty &&
                      state.status == UserChatStatus.connected) {
                    // Chờ tin nhắn chào mừng từ server, hoặc có thể hiển thị "Đang chờ hỗ trợ viên..."
                    return const Center(
                        child: Text('Đang chờ tin nhắn chào mừng...'));
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      // Xác định isMine dựa trên senderId và _currentUserId đã lưu
                      final bool isActuallyMine =
                          message.senderId == _currentUserId;
                      return _buildMessageItem(message, isActuallyMine);
                    },
                  );
                }
                if (state.status == UserChatStatus.error) {
                  return Center(
                      child: Text(
                          'Lỗi: ${state.errorMessage ?? "Không xác định"}'));
                }
                // Trạng thái initial và chưa có message
                return const Center(child: Text('Bắt đầu cuộc trò chuyện...'));
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessageModel message, bool isActuallyMine) {
    return Align(
      alignment: isActuallyMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width *
              0.75, // Giới hạn chiều rộng của bubble chat
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
            color: isActuallyMine
                ? Theme.of(context).primaryColor.withAlpha(200) // Màu của bạn
                : Colors.grey[300], // Màu của người khác/hệ thống
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16.0),
              topRight: const Radius.circular(16.0),
              bottomLeft: isActuallyMine
                  ? const Radius.circular(16.0)
                  : const Radius.circular(0),
              bottomRight: isActuallyMine
                  ? const Radius.circular(0)
                  : const Radius.circular(16.0),
            )),
        child: Column(
          crossAxisAlignment: isActuallyMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActuallyMine && message.senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 3.0),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isActuallyMine
                        ? Colors.white70
                        : Theme.of(context).primaryColorDark,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                  color: isActuallyMine ? Colors.white : Colors.black87,
                  fontSize: 15),
            ),
            const SizedBox(height: 5.0),
            Text(
              DateFormat('HH:mm').format(
                  message.timestamp.toLocal()), // Hiển thị giờ địa phương
              style: TextStyle(
                fontSize: 10.0,
                color: isActuallyMine
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 1,
            color: Colors.grey.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Có thể thêm nút đính kèm file, icon,... ở đây
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .scaffoldBackgroundColor, // Hoặc một màu nền khác
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              minLines: 1,
              maxLines: 5, // Cho phép nhập nhiều dòng
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
