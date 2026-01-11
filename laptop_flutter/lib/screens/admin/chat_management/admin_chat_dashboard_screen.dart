import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Để định dạng thời gian

import '../../../blocs/admin_management/chat_management/admin_chat_bloc.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../models/admin_conversation_model.dart';
import '../../../repositories/auth_repository.dart';
import 'admin_detailed_chat_screen.dart'; // Để lấy token

class AdminChatDashboardScreen extends StatefulWidget {
  const AdminChatDashboardScreen({super.key});

  @override
  State<AdminChatDashboardScreen> createState() =>
      _AdminChatDashboardScreenState();
}

class _AdminChatDashboardScreenState extends State<AdminChatDashboardScreen> {
  late AdminChatBloc _adminChatBloc;

  @override
  void initState() {
    super.initState();
    _adminChatBloc = BlocProvider.of<AdminChatBloc>(context);
    final authState = BlocProvider.of<AuthBloc>(context).state;
    final authRepository = RepositoryProvider.of<AuthRepository>(context);

    if (authState is AuthAuthenticated && authState.user.role == 1) {
      // Đảm bảo là admin
      authRepository.getToken().then((token) {
        if (token != null && token.isNotEmpty) {
          if (mounted) {
            _adminChatBloc.add(ConnectAdminChatServer(token));
          }
        } else {
          _showErrorSnackbar("Admin token not found.");
        }
      }).catchError((error) {
        _showErrorSnackbar("Error getting admin token: $error");
      });
    } else {
      _showErrorSnackbar("Admin not authenticated.");
      // Có thể điều hướng ra nếu admin không được xác thực
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    // Quyết định xem có ngắt kết nối khi admin rời dashboard không
    // _adminChatBloc.add(DisconnectAdminChatServer());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar đã có ở AdminMainScreen, không cần ở đây trừ khi muốn custom
      body: BlocConsumer<AdminChatBloc, AdminChatState>(
        bloc: _adminChatBloc,
        listener: (context, state) {
          if (state.status == AdminChatStatus.error &&
              state.errorMessage != null) {
            _showErrorSnackbar(state.errorMessage!);
          }
        },
        builder: (context, state) {
          if (state.status == AdminChatStatus.connecting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AdminChatStatus.disconnected) {
            return _buildDisconnectedView(context);
          }

          if (state.status == AdminChatStatus.connected ||
              state.status == AdminChatStatus.initial) {
            if (state.conversations.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Chưa có cuộc trò chuyện nào.\nKhi khách hàng bắt đầu chat, chúng sẽ xuất hiện ở đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }

            // Lấy danh sách conversations và sắp xếp (đã được sắp xếp trong BLoC)
            final conversationsList = state.conversations.values.toList();

            return ListView.separated(
              itemCount: conversationsList.length,
              itemBuilder: (context, index) {
                final conversation = conversationsList[index];
                return _buildConversationItem(context, conversation,
                    state.onlineUserIds.contains(conversation.userId));
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            );
          }
          return const Center(child: Text('Đang tải dữ liệu tư vấn...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null, // Tag duy nhất
        onPressed: () {
          _adminChatBloc.add(RefreshAdminConversations());
        },
        tooltip: 'Làm mới',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildDisconnectedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Đã ngắt kết nối với máy chủ chat (Admin).'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final authState = BlocProvider.of<AuthBloc>(context).state;
              final authRepository =
                  RepositoryProvider.of<AuthRepository>(context);
              if (authState is AuthAuthenticated && authState.user.role == 1) {
                authRepository.getToken().then((token) {
                  if (token != null && token.isNotEmpty) {
                    if (mounted)
                      _adminChatBloc.add(ConnectAdminChatServer(token));
                  }
                });
              }
            },
            child: const Text('Kết nối lại'),
          )
        ],
      ),
    );
  }

  Widget _buildConversationItem(BuildContext context,
      AdminConversationModel conversation, bool isOnline) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            // backgroundImage: conversation.userAvatar != null ? NetworkImage(conversation.userAvatar!) : null,
            // child: conversation.userAvatar == null ? const Icon(Icons.person_outline) : null,
            backgroundColor: Colors
                .accents[conversation.userId.hashCode % Colors.accents.length]
                .withAlpha(50),
            child: Text(
                conversation.userName.isNotEmpty
                    ? conversation.userName[0].toUpperCase()
                    : "?",
                style: TextStyle(
                    color: Colors
                        .accents[conversation.userId.hashCode %
                            Colors.accents.length]
                        .shade700)),
          ),
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5)),
                child: const CircleAvatar(
                  radius: 5,
                  backgroundColor: Colors.green,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        conversation.userName,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conversation.lastMessage?.text ?? 'Chưa có tin nhắn',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessage != null)
            Text(
              DateFormat('HH:mm')
                  .format(conversation.lastMessage!.timestamp.toLocal()),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          const SizedBox(height: 4),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: () {
        _adminChatBloc.add(SelectConversation(conversation.userId));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (newContext) => BlocProvider.value(
              value:
                  _adminChatBloc, // _adminChatBloc lấy từ context của AdminChatDashboardScreen
              child: AdminDetailedChatScreen(
                userId: conversation.userId,
                userName: conversation.userName,
              ),
            ),
          ),
        );
      },
    );
  }
}
