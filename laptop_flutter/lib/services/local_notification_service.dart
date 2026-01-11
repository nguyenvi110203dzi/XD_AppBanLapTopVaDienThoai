// lib/services/local_notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Import các màn hình và Bloc cần thiết cho điều hướng từ thông báo
import 'package:laptop_flutter/blocs/admin_management/credit_order_management/admin_credit_order_detail_bloc.dart';
import 'package:laptop_flutter/blocs/credit_order_detail/credit_order_detail_bloc.dart'; // Client's BLoC
import 'package:laptop_flutter/repositories/auth_repository.dart';
import 'package:laptop_flutter/repositories/credit_order_repository.dart';
import 'package:laptop_flutter/screens/admin/credit_order/admin_credit_order_detail_screen.dart';
import 'package:laptop_flutter/screens/client/credit_customer/credit_order_detail_screen.dart'; // Client's screen

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings(
          '@mipmap/ic_launcher'), // Đảm bảo icon này tồn tại trong android/app/src/main/res/mipmap
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      ),
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onDidReceiveBackgroundNotificationResponse,
    );
  }

  static void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    print(
        'onDidReceiveLocalNotification: id: $id, title: $title, body: $body, payload: $payload');
    // Xử lý khi nhận thông báo lúc app đang mở trên iOS version < 10
  }

  static void _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      print('Notification tapped, payload: $payload');
      final navigatorContext = _navigatorKey?.currentContext;
      if (navigatorContext == null) {
        print("Navigator context is null, cannot navigate.");
        return;
      }

      if (payload.startsWith("admin_credit_reminder_")) {
        // Đổi tên payload cho admin để phân biệt
        final orderIdString =
            payload.substring("admin_credit_reminder_".length);
        final orderId = int.tryParse(orderIdString);
        if (orderId != null && _navigatorKey?.currentState != null) {
          _navigatorKey!.currentState!.push(
            MaterialPageRoute(
              builder: (context) => MultiRepositoryProvider(
                providers: [
                  RepositoryProvider.value(
                      value: RepositoryProvider.of<AuthRepository>(
                          navigatorContext)),
                  RepositoryProvider.value(
                      value: RepositoryProvider.of<CreditOrderRepository>(
                          navigatorContext)),
                ],
                child: BlocProvider<AdminCreditOrderDetailBloc>(
                  create: (ctx) => AdminCreditOrderDetailBloc(
                    creditOrderRepository:
                        RepositoryProvider.of<CreditOrderRepository>(ctx),
                  )..add(LoadAdminCreditOrderDetail(orderId)),
                  child: AdminCreditOrderDetailScreen(orderId: orderId),
                ),
              ),
            ),
          );
        }
      } else if (payload.startsWith("user_credit_reminder_")) {
        final orderIdString = payload.substring("user_credit_reminder_".length);
        final orderId = int.tryParse(orderIdString);
        if (orderId != null && _navigatorKey?.currentState != null) {
          _navigatorKey!.currentState!.push(
            MaterialPageRoute(
              builder: (context) => MultiRepositoryProvider(
                providers: [
                  RepositoryProvider.value(
                      value: RepositoryProvider.of<AuthRepository>(
                          navigatorContext)),
                  RepositoryProvider.value(
                      value: RepositoryProvider.of<CreditOrderRepository>(
                          navigatorContext)),
                ],
                child: BlocProvider<CreditOrderDetailBloc>(
                  create: (ctx) => CreditOrderDetailBloc(
                    creditOrderRepository:
                        RepositoryProvider.of<CreditOrderRepository>(ctx),
                  )..add(LoadMyCreditOrderDetail(orderId)),
                  child: CreditOrderDetailScreen(orderId: orderId),
                ),
              ),
            ),
          );
        }
      } else if (payload.startsWith("chat_conversation_")) {
        // Xử lý cho chat
        final conversationId = payload.substring("chat_conversation_".length);
        // Ví dụ điều hướng đến màn hình chat chi tiết của admin
        // Cần đảm bảo AdminChatDashboardScreen hoặc màn hình cha của nó cung cấp AdminChatBloc
        if (_navigatorKey?.currentState != null) {
          // Giả sử bạn có một route /admin_chat_detail hoặc một màn hình cụ thể
          // và AdminChatBloc được cung cấp ở mức cao hơn hoặc qua màn hình dashboard
          // Nếu AdminDetailedChatScreen được push từ AdminChatDashboardScreen,
          // bạn có thể cần truyền conversationId qua arguments hoặc một BLoC khác
          print("Navigate to admin chat with conversationId: $conversationId");
          // Ví dụ:
          // _navigatorKey!.currentState!.pushNamed('/admin_chat_detail_route', arguments: conversationId);
          // Hoặc nếu bạn điều hướng đến một màn hình có sẵn AdminChatBloc:
          // _navigatorKey!.currentState!.push(MaterialPageRoute(builder: (context) =>
          //   BlocProvider.value(
          //     value: BlocProvider.of<AdminChatBloc>(navigatorContext), // Lấy bloc từ context của key
          //     child: AdminDetailedChatScreen(userId: conversationId, userName: "User"), // Cần lấy userName đúng
          //   )
          // ));
          ScaffoldMessenger.of(navigatorContext).showSnackBar(
            SnackBar(
                content: Text(
                    'Mở cuộc trò chuyện: $conversationId (Cần xử lý điều hướng chi tiết)')),
          );
        }
      }
    }
  }

  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      print('Background notification tapped, payload: $payload');
      // TODO: Xử lý logic khi app bị terminated. Thường sẽ lưu payload
      // và xử lý khi app khởi động lại.
    }
  }

  static Future<void> showConsultationNotification({
    required String userName,
    required String messageText,
    required String conversationId, // Sửa thành conversationId
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'new_consultation_channel_id',
      'Yêu cầu tư vấn mới',
      channelDescription: 'Thông báo khi có yêu cầu tư vấn mới từ người dùng.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'Yêu cầu tư vấn mới',
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    final int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final String title = 'Yêu Cầu Tư Vấn Mới!';
    final String body =
        'Từ: $userName\n${messageText.length > 100 ? messageText.substring(0, 97) + "..." : messageText}';

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload:
          'chat_conversation_$conversationId', // Sử dụng conversationId làm payload
    );
  }

  // Hàm MỚI cho thông báo nhắc công nợ của User
  static Future<void> showUserDebtReminderNotification({
    required int orderId,
    required String message,
    String? dueDate,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'user_debt_reminder_channel_id', // ID channel mới cho user
      'Nhắc nhở Công Nợ Khách Hàng', // Tên channel
      channelDescription:
          'Thông báo nhắc nhở thanh toán công nợ cho khách hàng.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'Nhắc nhở công nợ',
    );
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    final int notificationId =
        orderId + 200000; // Đảm bảo ID khác với các loại thông báo khác
    final String title = 'Nhắc Nhở Thanh Toán Công Nợ';
    final String body = message; // message từ server

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload:
          'user_credit_reminder_$orderId', // Payload để điều hướng đến chi tiết đơn của user
    );
  }

  // Hàm MỚI cho thông báo nhắc công nợ cho Admin
  static Future<void> showAdminDebtReminderNotification({
    required int orderId,
    required String message, // messageToAdmin từ server
    String? userName,
    String? dueDate,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'admin_debt_reminder_channel_id', // ID channel mới cho admin
      'Cảnh Báo Công Nợ Admin', // Tên channel
      channelDescription: 'Thông báo cho Admin về các công nợ sắp đến hạn.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'Cảnh báo công nợ',
    );
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    final int notificationId = orderId + 300000; // Đảm bảo ID khác
    final String title = 'Cảnh Báo Công Nợ Sắp Hạn';
    // final String body = 'KH: $userName\n${message}';
    final String body = message; // messageToAdmin từ server

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload:
          'admin_credit_reminder_$orderId', // Payload để điều hướng đến chi tiết đơn của admin
    );
  }
}
