import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import BLoC, State, Event, Model, Repository
// Đảm bảo đường dẫn import chính xác
import '../../../blocs/admin_management/thongso_management/cauhinh/cauhinh_bloc.dart';
import '../../../models/cauhinhbonho.dart';
// Import màn hình Add/Edit
import 'admin_cauhinh_add_edit_screen.dart';

class AdminCauHinhListScreen extends StatefulWidget {
  const AdminCauHinhListScreen({super.key});

  @override
  State<AdminCauHinhListScreen> createState() => _AdminCauHinhListScreenState();
}

class _AdminCauHinhListScreenState extends State<AdminCauHinhListScreen> {
  // Map để lưu tên sản phẩm theo ID (tối ưu hơn gọi API liên tục)
  // Map<int, String> _productNames = {}; // Sẽ lấy từ state của Bloc
  // bool _isLoadingProductNames = false;

  @override
  void initState() {
    super.initState();
    // Load danh sách cấu hình và danh sách điện thoại (trong Bloc)
    context.read<CauHinhBloc>().add(LoadAllCauHinh());
  }

  // Hàm refresh
  Future<void> _refreshList() async {
    context.read<CauHinhBloc>().add(LoadAllCauHinh());
  }

  // Hàm xử lý xóa
  void _handleDelete(BuildContext context, CauhinhBonho cauHinh) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
              'Bạn có chắc muốn xóa cấu hình ID: ${cauHinh.id}? Thao tác này cũng sẽ bỏ gán cấu hình khỏi sản phẩm (nếu có).'),
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
                context.read<CauHinhBloc>().add(DeleteCauHinh(cauHinh.id));
              },
            ),
          ],
        );
      },
    );
  }

  // Hàm điều hướng đến màn hình Add/Edit
  void _navigateToAddEditScreen(BuildContext context,
      {CauhinhBonho? cauHinhToEdit}) {
    final currentState = context.read<CauHinhBloc>().state;
    // Chỉ điều hướng nếu đã load xong danh sách điện thoại
    if (currentState.status == CauHinhStatus.loaded ||
        currentState.status == CauHinhStatus.success) {
      Navigator.push<bool>(
        // Chờ kết quả bool
        context,
        MaterialPageRoute(
          // Cung cấp CauHinhBloc cho màn hình Add/Edit
          builder: (_) => BlocProvider.value(
            value:
                context.read<CauHinhBloc>(), // Dùng lại Bloc từ màn hình list
            child: AdminCauHinhAddEditScreen(
              cauHinhToEdit: cauHinhToEdit,
              // Truyền danh sách điện thoại đã load vào state
              phoneOptions: currentState.phoneOptions,
            ),
          ),
        ),
      ).then((success) {
        // Load lại danh sách nếu màn hình Add/Edit trả về true
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
        title: const Text('Quản lý Cấu hình Bộ nhớ'),
        actions: [
          // Nút refresh chỉ hoạt động khi không loading
          BlocBuilder<CauHinhBloc, CauHinhState>(builder: (context, state) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed:
                  state.status == CauHinhStatus.loading ? null : _refreshList,
              tooltip: 'Tải lại',
            );
          }),
        ],
      ),
      body: BlocConsumer<CauHinhBloc, CauHinhState>(
        listener: (context, state) {
          // Hiển thị SnackBar cho các thông báo thành công/lỗi (trừ lúc load)
          if (state.status != CauHinhStatus.loading && state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.message!),
                backgroundColor: state.status == CauHinhStatus.failure
                    ? Colors.red
                    : Colors.green,
                duration:
                    const Duration(seconds: 2), // Thời gian hiển thị ngắn hơn
              ));
          }
        },
        builder: (context, state) {
          // --- Trạng thái Loading ban đầu ---
          if (state.status == CauHinhStatus.initial ||
              (state.status == CauHinhStatus.loading &&
                  state.cauHinhList.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- Trạng thái Lỗi ban đầu ---
          if (state.status == CauHinhStatus.failure &&
              state.cauHinhList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text('Lỗi tải danh sách:',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 5),
                    Text(state.message ?? 'Không thể tải dữ liệu.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      onPressed: _refreshList,
                    )
                  ],
                ),
              ),
            );
          }
          // --- Danh sách rỗng ---
          if (state.cauHinhList.isEmpty &&
              state.status == CauHinhStatus.loaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings_input_component_outlined,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text('Chưa có cấu hình nào được tạo.'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo cấu hình mới'),
                    onPressed: () => _navigateToAddEditScreen(context),
                  )
                ],
              ),
            );
          }

          // --- Hiển thị danh sách ---
          return RefreshIndicator(
            onRefresh: _refreshList,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: state.cauHinhList.length,
              itemBuilder: (context, index) {
                final cauHinh = state.cauHinhList[index];
                // Tìm tên sản phẩm từ danh sách phoneOptions trong state
                final assignedPhone = state.phoneOptions
                    .firstWhereOrNull((phone) => phone.id == cauHinh.idProduct);
                final productName = assignedPhone?.name ?? 'Chưa gán';
                final productIdText =
                    assignedPhone != null ? '(ID: ${cauHinh.idProduct})' : '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    // Hiển thị thông tin chính của cấu hình
                    title: Text(
                      '${cauHinh.hedieuhanh} - ${cauHinh.chipCPU ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'RAM: ${cauHinh.ram ?? 'N/A'} - Lưu trữ: ${cauHinh.dungluongLuutru ?? 'N/A'}'),
                        const SizedBox(height: 4),
                        // Hiển thị sản phẩm được gán
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
                              color: Colors.blueAccent), // Icon khác
                          tooltip: 'Sửa',
                          iconSize: 22, // Kích thước icon nhỏ hơn
                          onPressed: () => _navigateToAddEditScreen(context,
                              cauHinhToEdit: cauHinh),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent), // Icon khác
                          tooltip: 'Xóa',
                          iconSize: 22,
                          onPressed: () => _handleDelete(context, cauHinh),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToAddEditScreen(context,
                        cauHinhToEdit: cauHinh),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        tooltip: 'Thêm cấu hình mới',
        child: const Icon(Icons.add),
      ),
    );
  }
}
