// lib/screens/admin/banner/admin_banner_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Import BLoC, Repo, Model của Banner
import 'package:laptop_flutter/blocs/admin_management/banner_management/banner_management_bloc.dart';
import 'package:laptop_flutter/repositories/auth_repository.dart';
import 'package:laptop_flutter/repositories/banner_repository.dart';

// Import màn hình Add/Edit Banner
import 'admin_add_edit_banner_screen.dart';

class AdminBannerManagementScreen extends StatelessWidget {
  const AdminBannerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => BannerRepository(
        // Cung cấp BannerRepository
        authRepository: context.read<AuthRepository>(),
      ),
      child: BlocProvider(
        create: (context) => BannerManagementBloc(
          // Cung cấp BannerManagementBloc
          bannerRepository: context.read<BannerRepository>(),
        )..add(LoadBanners()), // Tải danh sách banners
        child: Scaffold(
          body: BlocListener<BannerManagementBloc, BannerManagementState>(
            // Lắng nghe BannerManagementBloc
            listener: (context, state) {
              if (state is BannerOperationSuccess) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green),
                  );
              } else if (state is BannerOperationFailure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                        content: Text('Lỗi: ${state.error}'),
                        backgroundColor: Colors.red),
                  );
              }
            },
            child: BlocBuilder<BannerManagementBloc, BannerManagementState>(
              // Build UI theo BannerManagementBloc
              builder: (context, state) {
                if (state is BannerLoading ||
                    state is BannerOperationInProgress &&
                        state is! BannerLoadSuccess) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is BannerLoadSuccess) {
                  final banners = state.banners;
                  if (banners.isEmpty) {
                    return const Center(child: Text('Không có banner nào.'));
                  }
                  return ListView.builder(
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      final banner = banners[index];
                      return Card(
                        // Dùng Card cho đẹp hơn
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: banner.image.isNotEmpty
                              ? Image.network(
                                  context
                                          .read<BannerRepository>()
                                          .authRepository
                                          .baseUrl +
                                      banner.image, // Hiển thị ảnh
                                  width: 80, // Rộng hơn chút
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error, size: 40),
                                )
                              : const Icon(Icons.image_not_supported,
                                  size: 40), // Icon nếu không có ảnh
                          title: Text(banner.name ??
                              'Không có tên'), // Tên banner (có thể null)
                          subtitle: Text(
                            banner.status == 1
                                ? 'Đang hoạt động'
                                : 'Không hoạt động', // Hiển thị trạng thái
                            style: TextStyle(
                              color: banner.status == 1
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Builder(builder: (buttonContext) {
                                return IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orange),
                                  onPressed: () {
                                    Navigator.push(
                                      buttonContext,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: BlocProvider.of<
                                                  BannerManagementBloc>(
                                              buttonContext),
                                          child: AdminAddEditBannerScreen(
                                              banner: banner), // Điều hướng sửa
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
                              Builder(builder: (buttonContext) {
                                return IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(buttonContext,
                                        banner.id); // Gọi dialog xóa
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is BannerLoadFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Lỗi tải danh sách danh mục: ${state.error}'),
                        const SizedBox(height: 10),
                        Builder(builder: (buttonContext) {
                          return ElevatedButton(
                            onPressed: () => buttonContext
                                .read<BannerManagementBloc>()
                                .add(LoadBanners()), // Thử lại
                            child: const Text('Thử lại'),
                          );
                        })
                      ],
                    ),
                  );
                }
                return const Center(child: Text('Đang tải...'));
              },
            ),
          ),
          floatingActionButton: Builder(builder: (buttonContext) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  buttonContext,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: BlocProvider.of<BannerManagementBloc>(
                          buttonContext), // Chia sẻ BLoC
                      child:
                          const AdminAddEditBannerScreen(), // Điều hướng thêm mới
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
              tooltip: 'Thêm danh mục', // Tooltip
            );
          }),
        ),
      ),
    );
  }

// Hàm hiển thị dialog xác nhận xóa
  void _showDeleteConfirmationDialog(BuildContext buttonContext, int bannerId) {
    showDialog(
      context: buttonContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
              'Bạn có chắc chắn muốn xóa banner này không?'), // Đổi nội dung
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () {
                buttonContext
                    .read<BannerManagementBloc>()
                    .add(DeleteBanner(id: bannerId)); // Event xóa banner
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
