import 'package:collection/collection.dart'; // Để dùng firstWhereOrNull
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import BLoC, State, Event, Model, Repository
// Đảm bảo đường dẫn import chính xác
import '../../../blocs/admin_management/thongso_management/camera/camera_bloc.dart';
import '../../../models/cameramanhinh.dart';
import 'admin_camera_add_edit_screen.dart'; // << Thay bằng CameraManhinh model

class AdminCameraListScreen extends StatefulWidget {
  const AdminCameraListScreen({super.key});

  @override
  State<AdminCameraListScreen> createState() => _AdminCameraListScreenState();
}

class _AdminCameraListScreenState extends State<AdminCameraListScreen> {
  @override
  void initState() {
    super.initState();
    // Load danh sách camera và danh sách điện thoại (trong Bloc)
    context
        .read<CameraBloc>()
        .add(LoadAllCamera()); // << Gọi event LoadAllCamera
  }

  Future<void> _refreshList() async {
    context
        .read<CameraBloc>()
        .add(LoadAllCamera()); // << Gọi event LoadAllCamera
  }

  // Hàm xử lý xóa
  void _handleDelete(BuildContext context, CameraManhinh cameraSpec) {
    // << Tham số là CameraManhinh
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
              'Bạn có chắc muốn xóa thông số Camera/Màn hình ID: ${cameraSpec.id}? Thao tác này cũng sẽ bỏ gán khỏi sản phẩm (nếu có).'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Dispatch event xóa đến BLoC
                context.read<CameraBloc>().add(
                    DeleteCamera(cameraSpec.id)); // << Gọi event DeleteCamera
              },
            ),
          ],
        );
      },
    );
  }

  // Hàm điều hướng đến màn hình Add/Edit
  void _navigateToAddEditScreen(BuildContext context,
      {CameraManhinh? cameraToEdit}) {
    // << Tham số là CameraManhinh
    final currentState = context.read<CameraBloc>().state;
    // Chỉ điều hướng nếu đã load xong danh sách điện thoại
    if (currentState.status == CameraStatus.loaded ||
        currentState.status == CameraStatus.success) {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<CameraBloc>(), // Dùng lại CameraBloc
            child: AdminCameraAddEditScreen(
              // << Màn hình Add/Edit Camera
              cameraToEdit: cameraToEdit,
              phoneOptions: currentState.phoneOptions, // Truyền phoneOptions
            ),
          ),
        ),
      ).then((success) {
        if (success == true) {
          _refreshList();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đang tải dữ liệu điện thoại, vui lòng thử lại sau.'),
            backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QL Camera & Màn hình'), // << Đổi tiêu đề
        actions: [
          BlocBuilder<CameraBloc, CameraState>(// << Dùng CameraBloc
              builder: (context, state) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed:
                  state.status == CameraStatus.loading ? null : _refreshList,
              tooltip: 'Tải lại',
            );
          }),
        ],
      ),
      body: BlocConsumer<CameraBloc, CameraState>(
        // << Dùng CameraBloc
        listener: (context, state) {
          if (state.status != CameraStatus.loading && state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.message!),
                backgroundColor: state.status == CameraStatus.failure
                    ? Colors.red
                    : Colors.green,
                duration: const Duration(seconds: 2),
              ));
          }
        },
        builder: (context, state) {
          if (state.status == CameraStatus.initial ||
              (state.status == CameraStatus.loading &&
                  state.cameraList.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == CameraStatus.failure &&
              state.cameraList.isEmpty) {
            return Center(/* Error UI */); // Giữ nguyên UI lỗi
          }
          if (state.cameraList.isEmpty && state.status == CameraStatus.loaded) {
            return Center(
              // UI danh sách rỗng
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      size: 60, color: Colors.grey), // << Đổi icon
                  const SizedBox(height: 10),
                  const Text(
                      'Chưa có thông số Camera/Màn hình nào.'), // << Đổi text
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo thông số mới'), // << Đổi text
                    onPressed: () => _navigateToAddEditScreen(context),
                  )
                ],
              ),
            );
          }

          // Hiển thị danh sách
          return RefreshIndicator(
            onRefresh: _refreshList,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: state.cameraList.length, // << Dùng cameraList
              itemBuilder: (context, index) {
                final cameraSpec =
                    state.cameraList[index]; // << Biến cameraSpec
                final assignedPhone = state.phoneOptions.firstWhereOrNull(
                    (phone) => phone.id == cameraSpec.idProduct);
                final productName = assignedPhone?.name ?? 'Chưa gán';
                final productIdText = assignedPhone != null
                    ? '(ID: ${cameraSpec.idProduct})'
                    : '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    // Hiển thị thông tin chính của Camera/Màn hình
                    title: Text(
                      'Cam sau: ${cameraSpec.dophangiaiCamsau}', // << Hiển thị thông tin camera
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Màn hình: ${cameraSpec.congngheManhinh ?? 'N/A'} - ${cameraSpec.rongManhinh ?? 'N/A'}'), // << Hiển thị thông tin màn hình
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                              text: 'Gán cho SP: ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                              children: [
                                TextSpan(
                                  text: productName,
                                  style: TextStyle(
                                      color: assignedPhone != null
                                          ? Colors.blue[700]
                                          : Colors.grey[600],
                                      fontStyle: assignedPhone == null
                                          ? FontStyle.italic
                                          : FontStyle.normal),
                                ),
                                TextSpan(
                                  text: ' $productIdText',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blueAccent),
                          tooltip: 'Sửa',
                          iconSize: 22,
                          onPressed: () => _navigateToAddEditScreen(context,
                              cameraToEdit:
                                  cameraSpec), // << Truyền cameraToEdit
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          tooltip: 'Xóa',
                          iconSize: 22,
                          onPressed: () => _handleDelete(
                              context, cameraSpec), // << Truyền cameraSpec
                        ),
                      ],
                    ),
                    onTap: () => _navigateToAddEditScreen(context,
                        cameraToEdit: cameraSpec),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        tooltip: 'Thêm Camera/Màn hình', // << Đổi tooltip
        child: const Icon(Icons.add),
      ),
    );
  }
}
