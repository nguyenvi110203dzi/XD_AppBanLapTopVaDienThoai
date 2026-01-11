import 'package:collection/collection.dart'; // Để dùng firstWhereOrNull
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import BLoC, State, Event, Model, Repository
// Đảm bảo đường dẫn import chính xác
import '../../../blocs/admin_management/thongso_management/pinsac/pinsac_bloc.dart';
import '../../../models/pinvasac.dart';
import 'admin_pinsac_add_edit_screen.dart'; // << PinSac model

class AdminPinSacListScreen extends StatefulWidget {
  const AdminPinSacListScreen({super.key});

  @override
  State<AdminPinSacListScreen> createState() => _AdminPinSacListScreenState();
}

class _AdminPinSacListScreenState extends State<AdminPinSacListScreen> {
  @override
  void initState() {
    super.initState();
    // Load danh sách pin/sạc và danh sách điện thoại (trong Bloc)
    context
        .read<PinSacBloc>()
        .add(LoadAllPinSac()); // << Gọi event LoadAllPinSac
  }

  Future<void> _refreshList() async {
    context
        .read<PinSacBloc>()
        .add(LoadAllPinSac()); // << Gọi event LoadAllPinSac
  }

  // Hàm xử lý xóa
  void _handleDelete(BuildContext context, PinSac pinSacSpec) {
    // << Tham số là PinSac
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
              'Bạn có chắc muốn xóa thông số Pin/Sạc ID: ${pinSacSpec.id}? Thao tác này cũng sẽ bỏ gán khỏi sản phẩm (nếu có).'),
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
                context.read<PinSacBloc>().add(
                    DeletePinSac(pinSacSpec.id)); // << Gọi event DeletePinSac
              },
            ),
          ],
        );
      },
    );
  }

  // Hàm điều hướng đến màn hình Add/Edit
  void _navigateToAddEditScreen(BuildContext context, {PinSac? pinSacToEdit}) {
    // << Tham số là PinSac
    final currentState = context.read<PinSacBloc>().state;
    // Chỉ điều hướng nếu đã load xong danh sách điện thoại
    if (currentState.status == PinSacStatus.loaded ||
        currentState.status == PinSacStatus.success) {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<PinSacBloc>(), // Dùng lại PinSacBloc
            child: AdminPinSacAddEditScreen(
              // << Màn hình Add/Edit PinSac
              pinSacToEdit: pinSacToEdit,
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
        title: const Text('Quản lý Pin & Sạc'), // << Đổi tiêu đề
        actions: [
          BlocBuilder<PinSacBloc, PinSacState>(// << Dùng PinSacBloc
              builder: (context, state) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed:
                  state.status == PinSacStatus.loading ? null : _refreshList,
              tooltip: 'Tải lại',
            );
          }),
        ],
      ),
      body: BlocConsumer<PinSacBloc, PinSacState>(
        // << Dùng PinSacBloc
        listener: (context, state) {
          if (state.status != PinSacStatus.loading && state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.message!),
                backgroundColor: state.status == PinSacStatus.failure
                    ? Colors.red
                    : Colors.green,
                duration: const Duration(seconds: 2),
              ));
          }
        },
        builder: (context, state) {
          if (state.status == PinSacStatus.initial ||
              (state.status == PinSacStatus.loading &&
                  state.pinSacList.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == PinSacStatus.failure &&
              state.pinSacList.isEmpty) {
            return Center(/* Error UI */); // Giữ nguyên UI lỗi
          }
          if (state.pinSacList.isEmpty && state.status == PinSacStatus.loaded) {
            return Center(
              // UI danh sách rỗng
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.battery_charging_full_outlined,
                      size: 60, color: Colors.grey), // << Đổi icon
                  const SizedBox(height: 10),
                  const Text('Chưa có thông số Pin/Sạc nào.'), // << Đổi text
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
              itemCount: state.pinSacList.length, // << Dùng pinSacList
              itemBuilder: (context, index) {
                final pinSacSpec =
                    state.pinSacList[index]; // << Biến pinSacSpec
                final assignedPhone = state.phoneOptions.firstWhereOrNull(
                    (phone) => phone.id == pinSacSpec.idProduct);
                final productName = assignedPhone?.name ?? 'Chưa gán';
                final productIdText = assignedPhone != null
                    ? '(ID: ${pinSacSpec.idProduct})'
                    : '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    // Hiển thị thông tin chính của Pin/Sạc
                    title: Text(
                      'Pin: ${pinSacSpec.dungluongPin}', // << Hiển thị thông tin pin
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Sạc tối đa: ${pinSacSpec.hotrosacMax ?? 'N/A'} - Loại: ${pinSacSpec.loaiPin ?? 'N/A'}'), // << Hiển thị thông tin sạc
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
                              pinSacToEdit:
                                  pinSacSpec), // << Truyền pinSacToEdit
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          tooltip: 'Xóa',
                          iconSize: 22,
                          onPressed: () => _handleDelete(
                              context, pinSacSpec), // << Truyền pinSacSpec
                        ),
                      ],
                    ),
                    onTap: () => _navigateToAddEditScreen(context,
                        pinSacToEdit: pinSacSpec),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        tooltip: 'Thêm Pin/Sạc', // << Đổi tooltip
        child: const Icon(Icons.add),
      ),
    );
  }
}
