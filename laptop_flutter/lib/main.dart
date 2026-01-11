import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laptop_flutter/repositories/auth_repository.dart';
import 'package:laptop_flutter/repositories/category_repository.dart';
import 'package:laptop_flutter/repositories/credit_order_repository.dart';
import 'package:laptop_flutter/repositories/order_repository.dart';
import 'package:laptop_flutter/repositories/payment_repository.dart';
import 'package:laptop_flutter/repositories/spec_repository.dart';
import 'package:laptop_flutter/repositories/user_repository.dart';
import 'package:laptop_flutter/repositories/warehouse_repository.dart';
import 'package:laptop_flutter/screens/client/main_screens.dart';
import 'package:laptop_flutter/services/local_notification_service.dart';
import 'package:laptop_flutter/services/user_socket_service.dart';
import 'package:path_provider/path_provider.dart';

import 'blocs/admin_management/chat_management/admin_chat_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/brand/brand_bloc.dart';
import 'blocs/cart/cart_bloc.dart';
import 'blocs/category/category_bloc.dart';
import 'blocs/home/home_bloc.dart';
import 'repositories/banner_repository.dart';
import 'repositories/brand_repository.dart'; // Import repo
import 'repositories/product_repository.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  await LocalNotificationService.initialize(navigatorKey);
  // Cấu hình storage cho HydratedBloc
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb // Kiểm tra nếu là web
        ? HydratedStorage.webStorageDirectory // Dùng storage mặc định cho web
        : await getApplicationDocumentsDirectory(), // Dùng thư mục documents cho mobile
  ); // Lưu item sản phẩm vào bộ nhớ tạm
  final authRepository = AuthRepository();
  final bannerRepository = BannerRepository(authRepository: authRepository);
  final productRepository = ProductRepository(authRepository: authRepository);
  final brandRepository = BrandRepository(authRepository: authRepository);
  final categoryRepository = CategoryRepository(authRepository: authRepository);
  final orderRepository = OrderRepository(authRepository: authRepository);
  final userRepository = UserRepository(authRepository: authRepository);
  final specRepository = SpecRepository(authRepository: authRepository);
  final paymentRepository = PaymentRepository(authRepository: authRepository);
  final creditOrderRepository =
      CreditOrderRepository(authRepository: authRepository);
  final userSocketService = UserSocketService(authRepository);
  final warehouseRepository =
      WarehouseRepository(authRepository: authRepository);

  runApp(MyApp(
    authRepository: authRepository,
    bannerRepository: bannerRepository,
    productRepository: productRepository,
    brandRepository: brandRepository,
    categoryRepository: categoryRepository,
    orderRepository: orderRepository,
    userRepository: userRepository,
    specRepository: specRepository,
    paymentRepository: paymentRepository,
    creditOrderRepository: creditOrderRepository,
    userSocketService: userSocketService,
    warehouseRepository: warehouseRepository, // << TRUYỀN VÀO MyApp
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final BannerRepository bannerRepository;
  final ProductRepository productRepository;
  final BrandRepository brandRepository;
  final CategoryRepository categoryRepository;
  final OrderRepository orderRepository;
  final UserRepository userRepository;
  final SpecRepository specRepository;
  final PaymentRepository paymentRepository;
  final CreditOrderRepository creditOrderRepository;
  final UserSocketService userSocketService;
  final WarehouseRepository warehouseRepository;
  const MyApp({
    super.key,
    required this.authRepository,
    required this.bannerRepository,
    required this.productRepository,
    required this.brandRepository,
    required this.categoryRepository,
    required this.orderRepository,
    required this.userRepository,
    required this.specRepository,
    required this.paymentRepository,
    required this.creditOrderRepository,
    required this.userSocketService,
    required this.warehouseRepository,
  });

  @override
  Widget build(BuildContext context) {
    // Cung cấp repositories cho toàn ứng dụng nếu cần
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: bannerRepository),
        RepositoryProvider.value(value: productRepository),
        RepositoryProvider.value(value: brandRepository),
        RepositoryProvider.value(value: categoryRepository),
        RepositoryProvider.value(value: orderRepository),
        RepositoryProvider.value(value: userRepository),
        RepositoryProvider.value(value: specRepository),
        RepositoryProvider.value(value: paymentRepository),
        RepositoryProvider.value(value: creditOrderRepository),
        RepositoryProvider.value(value: userSocketService),
        RepositoryProvider.value(value: warehouseRepository),
        RepositoryProvider.value(
            value: warehouseRepository), // << SỬ DỤNG Ở ĐÂY
        // Thêm các repository khác nếu có
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            // Cung cấp AuthBloc
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(
                AuthAppStarted()), // << Gọi event kiểm tra đăng nhập khi tạo Bloc
          ),
          // Khởi tạo HomeBloc và cung cấp repositories cho nó
          BlocProvider<HomeBloc>(
            create: (context) => HomeBloc(
              bannerRepository: context.read<BannerRepository>(),
              productRepository: context.read<ProductRepository>(),
            )..add(LoadHomeData()), // Tải dữ liệu ngay khi tạo Bloc
          ),
          BlocProvider<BrandBloc>(
            // Cung cấp bloc
            create: (context) => BrandBloc(
              brandRepository: context.read<BrandRepository>(),
            )..add(LoadBrands()), // Load brands ngay khi tạo bloc
          ),
          BlocProvider<CategoryBloc>(
            // Cung cấp bloc
            create: (context) => CategoryBloc(
              categoryRepository: context.read<CategoryRepository>(),
            )..add(LoadCategories()), // Load categories ngay khi tạo bloc
          ),
          BlocProvider<CartBloc>(
            // << Thêm CartBloc Provider
            create: (_) => CartBloc(), // Khởi tạo CartBloc
          ),
          BlocProvider<AdminChatBloc>(
            create: (context) => AdminChatBloc(
              authBloc: BlocProvider.of<AuthBloc>(context),
              // Không tự động connect ở đây, AdminMainScreen sẽ connect khi cần
            ),
          ),
          // Thêm các BlocProvider khác nếu có
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Flutter BLoC Shop',
          theme: ThemeData(
            primarySwatch: Colors.orange, // Thay đổi màu chủ đạo nếu muốn
            appBarTheme: const AppBarTheme(
              // Tùy chỉnh AppBar theme
              backgroundColor: Colors.orange, // Màu nền AppBar
              foregroundColor: Colors.white, // Màu chữ và icon trên AppBar
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthUnauthenticated) {
          // Khi AuthBloc xác định xong trạng thái, điều hướng đến MainLayout
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainLayout()));
        }
        // Có thể thêm màn hình chờ ở đây
      },
      child: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
