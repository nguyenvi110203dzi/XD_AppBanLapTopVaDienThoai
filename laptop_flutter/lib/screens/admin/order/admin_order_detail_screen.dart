import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Import BLoC, State, Event
import '../../../blocs/admin_management/order_management/admin_order_detail_bloc.dart';
// Import Models
import '../../../models/order.dart';
import '../../../models/order_detail.dart'; // Cần model này

class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  int? _selectedStatus; // Lưu trạng thái được chọn trong dropdown
  late AdminOrderDetailBloc _bloc; // Giữ tham chiếu đến Bloc

  @override
  void initState() {
    super.initState();
    _bloc = context.read<AdminOrderDetailBloc>(); // Lấy bloc từ context
    // Event load chi tiết đã được gọi khi Bloc được tạo trong Navigator
  }

  // Định nghĩa các trạng thái
  final Map<int, String> statusMap = {
    0: 'Chờ xác nhận',
    1: 'Đã xác nhận',
    2: 'Đang giao',
    3: 'Đã giao',
    4: 'Đã hủy',
  };

  // Helper để lấy màu trạng thái (có thể đưa vào utils)
  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.purple;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết Đơn hàng #${widget.orderId}'),
        leading: IconButton(
          // Thêm nút back rõ ràng hơn
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pop(), // Chỉ pop, không cần result ở đây
        ),
      ),
      body: BlocConsumer<AdminOrderDetailBloc, AdminOrderDetailState>(
        listener: (context, state) {
          // Xử lý thông báo khi cập nhật/xóa thành công hoặc thất bại
          if (state is AdminOrderStatusUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Cập nhật trạng thái thành công!'),
                  backgroundColor: Colors.green),
            );
            // Cập nhật lại giá trị dropdown sau khi thành công
            setState(() {
              _selectedStatus = state.updatedOrder.status;
            });
          } else if (state is AdminOrderStatusUpdateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Cập nhật thất bại: ${state.error}'),
                  backgroundColor: Colors.red),
            );
            // Reset dropdown về giá trị cũ nếu thất bại
            setState(() {
              _selectedStatus = state.originalOrder.status;
            });
          } else if (state is AdminOrderDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Xóa đơn hàng thành công!'),
                  backgroundColor: Colors.green),
            );
            // Quay lại màn hình danh sách sau khi xóa thành công
            Navigator.of(context)
                .pop(true); // Trả về true để báo hiệu cần load lại list
          } else if (state is AdminOrderDeleteFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Xóa đơn hàng thất bại: ${state.error}'),
                  backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          // --- Xử lý các trạng thái Loading / Error ---
          if (state is AdminOrderDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AdminOrderDetailLoadFailure) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${state.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    onPressed: () =>
                        _bloc.add(LoadAdminOrderDetail(widget.orderId)),
                  )
                ],
              ),
            ));
          }

          // --- Xử lý các trạng thái hiển thị dữ liệu ---
          // Lấy order từ state (Loaded, Updating, UpdateSuccess, UpdateFailure, Deleting, DeleteFailure)
          OrderModel? order;
          if (state is AdminOrderDetailLoaded) order = state.order;
          if (state is AdminOrderStatusUpdating) order = state.order;
          if (state is AdminOrderStatusUpdateSuccess)
            order = state.updatedOrder;
          if (state is AdminOrderStatusUpdateFailure)
            order = state.originalOrder;
          if (state is AdminOrderDeleteFailure) order = state.originalOrder;
          if (order == null &&
              state is! AdminOrderDetailInitial &&
              state is! AdminOrderDetailLoading &&
              state is! AdminOrderDetailLoadFailure) {
            // Ví dụ: nếu state là AdminOrderDeleting mà order là null
            if (state is AdminOrderDeleting) {
              // Có thể hiển thị loading indicator hoặc giữ UI cũ (nếu đã lưu order vào biến state của Widget)
              // Cách đơn giản là return loading
              return const Center(
                  child:
                      Text("Đang xử lý...")); // Hoặc giữ UI cũ nếu phức tạp hơn
            }
            return const Center(
                child: Text(
                    'Không có dữ liệu đơn hàng hoặc trạng thái không xác định.'));
          }
          if (order == null &&
              (state is AdminOrderDetailInitial ||
                  state is AdminOrderDetailLoading)) {
            return const Center(
                child: CircularProgressIndicator()); // Vẫn loading
          }
          if (order == null && state is AdminOrderDetailLoadFailure) {
            return Center(child: Text('Lỗi: ${state.error}')); // Vẫn lỗi
          }

          // Nếu không có dữ liệu order (trường hợp state Initial hoặc lỗi không mong muốn)
          if (order == null) {
            return const Center(child: Text('Không có dữ liệu đơn hàng.'));
          }

          // Gán giá trị ban đầu cho dropdown nếu chưa có hoặc khi load lại
          _selectedStatus ??= order.status;
          // Đảm bảo _selectedStatus luôn hợp lệ
          if (!statusMap.containsKey(_selectedStatus)) {
            _selectedStatus = order.status;
          }

          // --- Xây dựng giao diện chi tiết ---
          bool isUpdating = state is AdminOrderStatusUpdating;
          bool isDeleting = state is AdminOrderDeleting;

          return IgnorePointer(
            // Vô hiệu hóa thao tác khi đang loading action
            ignoring: isUpdating || isDeleting,
            child: Opacity(
              // Làm mờ đi một chút khi loading action
              opacity: (isUpdating || isDeleting) ? 0.6 : 1.0,
              child: Stack(
                // Sử dụng Stack để hiển thị loading indicator đè lên
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Thông tin khách hàng và đơn hàng ---
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Thông tin đơn hàng',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const Divider(),
                                _buildDetailRow('Mã đơn hàng:', '#${order.id}'),
                                _buildDetailRow(
                                    'Khách hàng:', order.user?.name ?? 'N/A'),
                                _buildDetailRow(
                                    'Email:', order.user?.email ?? 'N/A'),
                                _buildDetailRow(
                                    'Điện thoại:', order.user?.phone ?? 'N/A'),
                                _buildDetailRow(
                                    'Ngày đặt:',
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(order.createdAt.toLocal())),
                                _buildDetailRow('Tổng tiền:',
                                    formatCurrency.format(order.total ?? 0)),
                                _buildDetailRow(
                                    'Ghi chú:',
                                    order.note?.isNotEmpty ?? false
                                        ? order.note!
                                        : 'Không có'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Cập nhật trạng thái ---
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Trạng thái đơn hàng',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<int>(
                                  value: _selectedStatus,
                                  items: statusMap.entries.map((entry) {
                                    return DropdownMenuItem<int>(
                                      value: entry.key,
                                      child: Row(
                                        // Thêm màu vào Dropdown item
                                        children: [
                                          Icon(Icons.circle,
                                              color: _getStatusColor(entry.key),
                                              size: 12),
                                          const SizedBox(width: 8),
                                          Text(entry.value),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: isUpdating
                                      ? null
                                      : (newValue) {
                                          // Disable khi đang update
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedStatus = newValue;
                                            });
                                          }
                                        },
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    filled: true,
                                    fillColor: _getStatusColor(_selectedStatus!)
                                        .withOpacity(
                                            0.1), // Nền theo màu status
                                  ),
                                  // style: TextStyle(color: _getStatusColor(_selectedStatus!)), // Màu chữ dropdown
                                ),
                                const SizedBox(height: 15),
                                ElevatedButton.icon(
                                  icon: isUpdating
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ))
                                      : const Icon(Icons.save_alt), // Đổi icon
                                  label: const Text('Lưu thay đổi trạng thái'),
                                  onPressed: isUpdating ||
                                          _selectedStatus == order.status
                                      ? null // Disable nút
                                      : () {
                                          if (_selectedStatus != null) {
                                            _bloc.add(UpdateAdminOrderStatus(
                                                orderId: order!.id,
                                                newStatus: _selectedStatus!));
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 45)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- Chi tiết sản phẩm ---
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Chi tiết sản phẩm',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const Divider(),
                                if (order.details != null &&
                                    order.details!.isNotEmpty)
                                  _buildOrderDetailsList(order.details!,
                                      formatCurrency, _bloc.baseUrl)
                                else
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10.0),
                                      child:
                                          Text('Không có chi tiết sản phẩm.')),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // --- Nút xóa ---
                        Center(
                          // Đặt nút xóa ở giữa
                          child: OutlinedButton.icon(
                            icon: isDeleting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.red))
                                : const Icon(Icons.delete_forever_outlined,
                                    color: Colors.red),
                            label: const Text('Xóa đơn hàng này',
                                style: TextStyle(color: Colors.red)),
                            onPressed: isDeleting
                                ? null
                                : () {
                                    _showDeleteConfirmationDialog(
                                        context, order!.id);
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              // minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  // Hiển thị loading indicator đè lên nếu đang update/delete
                  if (isUpdating || isDeleting)
                    Container(
                      color: Colors.black.withOpacity(0.1), // Lớp phủ mờ
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget helper để hiển thị một dòng chi tiết
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100, // Cố định độ rộng của label
              child: Text('$label:',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.black54))),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Widget helper để hiển thị danh sách sản phẩm
  Widget _buildOrderDetailsList(
      List<OrderDetailModel> details, NumberFormat formatter, String baseUrl) {
    return ListView.separated(
      // Dùng separated để có đường kẻ giữa các item
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        final detail = details[index];
        final product = detail.products; // Lấy thông tin sản phẩm lồng nhau
        return ListTile(
          contentPadding: EdgeInsets.zero, // Bỏ padding mặc định
          leading: product?.image != null
              ? Image.network(
                  '$baseUrl${product!.image}', // Nối baseUrl
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50),
                )
              : const Icon(Icons.image_not_supported, size: 50),
          title: Text(
            product?.name ?? 'Sản phẩm không xác định',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('SL: ${detail.quantity}'),
          trailing: Text(formatter.format(detail.price)),
        );
      },
      separatorBuilder: (context, index) =>
          const Divider(height: 1), // Đường kẻ
    );
  }

  // Hàm hiển thị dialog xác nhận xóa
  void _showDeleteConfirmationDialog(BuildContext context, int orderId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Dùng BlocProvider.value để truyền Bloc hiện tại vào Dialog
        return BlocProvider.value(
          value: _bloc, // Truyền bloc từ màn hình chính
          child: AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text(
                'Bạn có chắc chắn muốn xóa đơn hàng này không? Dữ liệu liên quan có thể bị ảnh hưởng và hành động này không thể hoàn tác.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Hủy'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Đóng dialog
                },
              ),
              // Lắng nghe trạng thái xóa để hiển thị loading trong nút Xóa
              BlocBuilder<AdminOrderDetailBloc, AdminOrderDetailState>(
                builder: (ctx, state) {
                  bool isDeletingNow =
                      state is AdminOrderDeleting && state.orderId == orderId;
                  return TextButton(
                    child: isDeletingNow
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Xóa',
                            style: TextStyle(color: Colors.red)),
                    onPressed: isDeletingNow
                        ? null
                        : () {
                            // Không đóng dialog vội, để BLoC xử lý xong và listener sẽ đóng
                            _bloc.add(DeleteAdminOrder(orderId));
                          },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
