import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:laptop_flutter/blocs/admin_management/credit_order_management/admin_credit_order_detail_bloc.dart';
import 'package:laptop_flutter/models/credit_order.dart';

class AdminCreditOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const AdminCreditOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminCreditOrderDetailScreen> createState() =>
      _AdminCreditOrderDetailScreenState();
}

class _AdminCreditOrderDetailScreenState
    extends State<AdminCreditOrderDetailScreen> {
  int? _selectedStatus;
  DateTime? _selectedDueDate;
  final TextEditingController _noteController = TextEditingController();
  late AdminCreditOrderDetailBloc _bloc;

  final Map<int, String> _statusMap = {
    0: 'Chờ thanh toán',
    1: 'Đã thanh toán',
    2: 'Quá hạn',
    3: 'Đã hủy',
  };

  @override
  void initState() {
    super.initState();
    _bloc = context.read<AdminCreditOrderDetailBloc>();
    // Event load đã được gọi khi Bloc được tạo
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate(BuildContext context, DateTime? initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2000), // Cho phép chọn ngày trong quá khứ nếu cần sửa
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _saveChanges(CreditOrderModel currentOrder) {
    // Chỉ gửi những giá trị thực sự thay đổi
    int? statusToSend =
        (_selectedStatus != null && _selectedStatus != currentOrder.status)
            ? _selectedStatus
            : null;
    DateTime? dueDateToSend =
        (_selectedDueDate != null && _selectedDueDate != currentOrder.dueDate)
            ? _selectedDueDate
            : null;
    String? noteToSend =
        (_noteController.text.trim() != (currentOrder.note ?? ""))
            ? _noteController.text.trim()
            : null;

    // Nếu không có gì thay đổi thì không cần gọi API
    if (statusToSend == null && dueDateToSend == null && noteToSend == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có thay đổi nào để lưu.')),
      );
      return;
    }

    _bloc.add(UpdateAdminCreditOrder(
      orderId: widget.orderId,
      newStatus: statusToSend,
      newDueDate: dueDateToSend,
      newNote: noteToSend,
    ));
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange.shade700;
      case 1:
        return Colors.green.shade700;
      case 2:
        return Colors.red.shade800;
      case 3:
        return Colors.grey.shade600;
      default:
        return Colors.blueGrey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final formatDate = DateFormat('dd/MM/yyyy HH:mm');
    final formatDateOnly = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi Tiết Đơn Công Nợ #${widget.orderId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(
              false), // Pop false vì có thể không có gì thay đổi để load lại list
        ),
      ),
      body:
          BlocConsumer<AdminCreditOrderDetailBloc, AdminCreditOrderDetailState>(
        listener: (context, state) {
          if (state is AdminCreditOrderUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Cập nhật thành công!'),
                  backgroundColor: Colors.green),
            );
            // Cập nhật lại UI với dữ liệu mới từ state.updatedOrder
            setState(() {
              _selectedStatus = state.updatedOrder.status;
              _selectedDueDate = state.updatedOrder.dueDate;
              _noteController.text = state.updatedOrder.note ?? '';
            });
            // Thông báo cho màn hình list cần load lại
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop(true); // true để báo cần reload
              }
            });
          } else if (state is AdminCreditOrderUpdateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Cập nhật thất bại: ${state.error}'),
                  backgroundColor: Colors.red),
            );
            // Rollback to original values
            setState(() {
              _selectedStatus = state.originalOrder.status;
              _selectedDueDate = state.originalOrder.dueDate;
              _noteController.text = state.originalOrder.note ?? '';
            });
          } else if (state is AdminCreditOrderDetailLoaded) {
            // Gán giá trị ban đầu khi load xong
            if (_selectedStatus == null &&
                _selectedDueDate == null &&
                _noteController.text.isEmpty) {
              setState(() {
                _selectedStatus = state.order.status;
                _selectedDueDate = state.order.dueDate;
                _noteController.text = state.order.note ?? '';
              });
            }
          }
        },
        builder: (context, state) {
          if (state is AdminCreditOrderDetailLoading ||
              state is AdminCreditOrderDetailInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminCreditOrderDetailLoadFailure) {
            return Center(child: Text('Lỗi tải chi tiết: ${state.error}'));
          }

          CreditOrderModel? order;
          bool isUpdating = false;

          if (state is AdminCreditOrderDetailLoaded) order = state.order;
          if (state is AdminCreditOrderUpdating) {
            order = state.order;
            isUpdating = true;
          }
          if (state is AdminCreditOrderUpdateSuccess)
            order = state.updatedOrder;
          if (state is AdminCreditOrderUpdateFailure)
            order = state.originalOrder;

          if (order == null) {
            return const Center(child: Text('Không có dữ liệu đơn hàng.'));
          }

          // Đảm bảo _selectedStatus và _selectedDueDate có giá trị ban đầu
          _selectedStatus ??= order.status;
          _selectedDueDate ??= order.dueDate;
          if (_noteController.text.isEmpty &&
              (order.note?.isNotEmpty ?? false)) {
            _noteController.text = order.note!;
          }

          return IgnorePointer(
            ignoring: isUpdating,
            child: Opacity(
              opacity: isUpdating ? 0.6 : 1.0,
              child: Stack(children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thông tin khách hàng và đơn hàng
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mã đơn: #${order.id}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const Divider(),
                              if (order.user != null) ...[
                                _buildDetailRow('Khách hàng:', order.user!.name,
                                    avatarUrl: _bloc.baseUrl +
                                        (order.user!.avatar ?? '')),
                                _buildDetailRow('Email:', order.user!.email),
                                _buildDetailRow(
                                    'SĐT:', order.user!.phone ?? 'Chưa có'),
                              ],
                              _buildDetailRow('Ngày đặt:',
                                  formatDate.format(order.orderDate.toLocal())),
                              _buildDetailRow('Tổng tiền:',
                                  formatCurrency.format(order.total)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cập nhật trạng thái, ngày hẹn trả, ghi chú
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cập nhật đơn hàng',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const Divider(),
                              DropdownButtonFormField<int>(
                                value: _selectedStatus,
                                items: _statusMap.entries.map((entry) {
                                  return DropdownMenuItem<int>(
                                    value: entry.key,
                                    child: Row(children: [
                                      Icon(Icons.circle,
                                          color: _getStatusColor(entry.key),
                                          size: 12),
                                      const SizedBox(width: 8),
                                      Text(entry.value)
                                    ]),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedStatus = value);
                                },
                                decoration: const InputDecoration(
                                    labelText: 'Trạng thái',
                                    border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Ngày hẹn trả',
                                  hintText: _selectedDueDate != null
                                      ? formatDateOnly.format(_selectedDueDate!)
                                      : 'Chọn ngày',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                        Icons.calendar_today_outlined),
                                    onPressed: () => _pickDueDate(context,
                                        _selectedDueDate ?? order?.dueDate),
                                  ),
                                ),
                                onTap: () => _pickDueDate(context,
                                    _selectedDueDate ?? order?.dueDate),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _noteController,
                                decoration: const InputDecoration(
                                    labelText: 'Ghi chú của Admin',
                                    border: OutlineInputBorder()),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: isUpdating
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(Icons.save_alt_outlined),
                                  label: const Text('Lưu thay đổi'),
                                  onPressed: isUpdating
                                      ? null
                                      : () => _saveChanges(order!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chi tiết sản phẩm
                      Text(
                          'Chi tiết sản phẩm (${order.creditOrderDetails?.length ?? 0}):',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (order.creditOrderDetails == null ||
                          order.creditOrderDetails!.isEmpty)
                        const Text('Không có sản phẩm trong đơn hàng.')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.creditOrderDetails!.length,
                          itemBuilder: (context, index) {
                            final detail = order?.creditOrderDetails![index];
                            final product = detail?.product;
                            return Card(
                              elevation: 0.5,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: product?.image != null &&
                                        product!.image!.isNotEmpty
                                    ? Image.network(
                                        _bloc.baseUrl + product.image!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            Icon(Icons.broken_image))
                                    : const Icon(Icons.image_not_supported,
                                        size: 50),
                                title: Text(product?.name ?? 'N/A'),
                                subtitle: Text(
                                    'SL: ${detail?.quantity} - Giá: ${formatCurrency.format(detail!.price)}'),
                                trailing: Text(formatCurrency
                                    .format(detail!.quantity * detail.price)),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                if (isUpdating)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {String? avatarUrl}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.black54))),
          const SizedBox(width: 10),
          if (avatarUrl != null &&
              avatarUrl.isNotEmpty &&
              !avatarUrl.endsWith("null")) // Kiểm tra avatarUrl hợp lệ
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(avatarUrl),
                onBackgroundImageError: (e, s) =>
                    print("Lỗi tải avatar KH: $e"), // Để debug
                child: avatarUrl.endsWith("null")
                    ? const Icon(Icons.person, size: 12)
                    : null, // Fallback nếu NetworkImage lỗi
              ),
            ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
