import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/admin_management/chat_management/admin_chat_bloc.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../models/chat_message_model.dart';
// import '../../../models/user.dart'; // Admin user model (có thể không cần trực tiếp ở đây)

class AdminDetailedChatScreen extends StatefulWidget {
  final String userId; // ID của khách hàng đang chat
  final String userName;
  // final AdminChatBloc adminChatBloc; // Có thể truyền BLoC vào nếu không muốn lookup từ context

  const AdminDetailedChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    // required this.adminChatBloc,
  });

  @override
  State<AdminDetailedChatScreen> createState() =>
      _AdminDetailedChatScreenState();
}

class _AdminDetailedChatScreenState extends State<AdminDetailedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AdminChatBloc _adminChatBloc;
  String? _currentAdminId;

  @override
  void initState() {
    super.initState();
    _adminChatBloc = BlocProvider.of<AdminChatBloc>(context);
    // Khi màn hình này được mở, nghĩa là admin đã chọn cuộc trò chuyện này
    // BLoC đã xử lý việc chọn và reset unread count ở event SelectConversation
    // Chúng ta có thể dispatch lại SelectConversation để đảm bảo state được cập nhật đúng nếu cần
    // _adminChatBloc.add(SelectConversation(widget.userId));

    final authState = BlocProvider.of<AuthBloc>(context).state;
    if (authState is AuthAuthenticated && authState.user.role == 1) {
      _currentAdminId = authState.user.id.toString();
    }

    // Cuộn xuống cuối khi màn hình được build lần đầu nếu có tin nhắn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_adminChatBloc
              .state.chatMessagesByConversation[widget.userId]?.isNotEmpty ??
          false) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Khi admin rời màn hình chat chi tiết, có thể bỏ chọn cuộc trò chuyện hiện tại
    // để unread count hoạt động đúng cho cuộc trò chuyện này nếu có tin nhắn mới đến sau đó.
    // _adminChatBloc.add(const SelectConversation(null)); // Bỏ chọn conversation
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _adminChatBloc.add(SendAdminChatMessage(
        text: _messageController.text.trim(),
        recipientUserId: widget.userId, // Gửi đến user hiện tại
      ));
      _messageController.clear();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat với ${widget.userName}',
                style: const TextStyle(fontSize: 18)),
            // Hiển thị trạng thái online của user này nếu có
            BlocBuilder<AdminChatBloc, AdminChatState>(
              bloc: _adminChatBloc,
              builder: (context, state) {
                final isUserOnline =
                    state.onlineUserIds.contains(widget.userId);
                return Text(
                  isUserOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: isUserOnline
                        ? Colors.greenAccent.shade100
                        : Colors.white70,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<AdminChatBloc, AdminChatState>(
              bloc: _adminChatBloc,
              listener: (context, state) {
                if (state.status == AdminChatStatus.error &&
                    state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(state.errorMessage!),
                        backgroundColor: Colors.red),
                  );
                }
                // Cuộn xuống khi có tin nhắn mới trong cuộc trò chuyện hiện tại
                if (state.selectedConversationUserId == widget.userId &&
                    state.currentSelectedChatMessages.isNotEmpty) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                // Chỉ hiển thị tin nhắn của cuộc trò chuyện đang được chọn (widget.userId)
                final messagesForThisConversation =
                    state.chatMessagesByConversation[widget.userId] ?? [];

                if (state.status == AdminChatStatus.connecting &&
                    messagesForThisConversation.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messagesForThisConversation.isEmpty &&
                    state.status == AdminChatStatus.connected) {
                  return Center(
                      child:
                          Text('Bắt đầu trò chuyện với ${widget.userName}.'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messagesForThisConversation.length,
                  itemBuilder: (context, index) {
                    final message = messagesForThisConversation[index];
                    // Admin gửi (isMine = true) hoặc User gửi (isMine = false do _currentAdminId khác senderId của user)
                    final bool isActuallyMine =
                        message.senderId == _currentAdminId;
                    return _buildMessageItem(message, isActuallyMine);
                  },
                );
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  // _buildMessageItem và _buildMessageInputField có thể giống hệt như trong ChatScreen của User
  // Chỉ cần điều chỉnh màu sắc hoặc style nếu muốn phân biệt giao diện admin
  Widget _buildMessageItem(ChatMessageModel message, bool isActuallyMine) {
    return Align(
      alignment: isActuallyMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
            color: isActuallyMine
                ? Theme.of(context).colorScheme.secondary // Màu của Admin
                : Colors.grey[300], // Màu của User
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
            // Không cần hiển thị tên admin cho tin nhắn admin gửi
            // if (!isActuallyMine && message.senderName.isNotEmpty) ...
            Text(
              message.text,
              style: TextStyle(
                  color: isActuallyMine ? Colors.white : Colors.black87,
                  fontSize: 15),
            ),
            const SizedBox(height: 5.0),
            Text(
              DateFormat('HH:mm').format(message.timestamp.toLocal()),
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
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Trả lời ${widget.userName}...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8.0),
            Material(
              color: Theme.of(context)
                  .colorScheme
                  .secondary, // Màu nút gửi của Admin
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: _sendMessage,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
