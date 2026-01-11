// lib/screens/client/credit_customer/create_credit_order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:laptop_flutter/blocs/credit_order/create_credit_order_bloc.dart'; // Sẽ tạo Bloc này
import 'package:laptop_flutter/config/app_constants.dart';
import 'package:laptop_flutter/models/product.dart';
import 'package:laptop_flutter/repositories/credit_order_repository.dart';

class CreateCreditOrderScreen extends StatefulWidget {
  final List<ProductModel> selectedProducts;
  final Map<int, int> selectedQuantities; // Nhận thêm cái này

  const CreateCreditOrderScreen({
    super.key,
    required this.selectedProducts,
    required this.selectedQuantities, // Thêm vào constructor
  });

  @override
  State<CreateCreditOrderScreen> createState() =>
      _CreateCreditOrderScreenState();
}

class _CreateCreditOrderScreenState extends State<CreateCreditOrderScreen> {
  final _noteController = TextEditingController();
  DateTime? _selectedDueDate;
  final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  Future<void> _pickDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ??
          DateTime.now().add(const Duration(days: 7)), // Mặc định 7 ngày sau
      firstDate: DateTime.now()
          .add(const Duration(days: 1)), // Không cho chọn ngày quá khứ
      lastDate: DateTime.now().add(const Duration(days: 365)), // Giới hạn 1 năm
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int totalAmount = 0;
    for (var product in widget.selectedProducts) {
      totalAmount +=
          product.price * (widget.selectedQuantities[product.id] ?? 0);
    }

    return BlocProvider(
      create: (context) => CreateCreditOrderBloc(
        creditOrderRepository: context.read<CreditOrderRepository>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tạo Đơn Hàng Công Nợ'),
        ),
        body: BlocConsumer<CreateCreditOrderBloc, CreateCreditOrderState>(
          listener: (context, state) {
            if (state is CreateCreditOrderSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tạo đơn hàng công nợ thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop(
                  true); // Trả về true để màn hình trước biết và clear selection
            } else if (state is CreateCreditOrderFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi: ${state.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            bool isLoading = state is CreateCreditOrderInProgress;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sản phẩm đã chọn:',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.selectedProducts.length,
                    itemBuilder: (context, index) {
                      final product = widget.selectedProducts[index];
                      final quantity =
                          widget.selectedQuantities[product.id] ?? 0;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: product.image != null
                              ? Image.network(
                                  AppConstants.baseUrl + product.image!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover)
                              : const Icon(Icons.image_not_supported, size: 50),
                          title: Text(product.name),
                          subtitle: Text(
                              '${formatCurrency.format(product.price)} x $quantity'),
                          trailing: Text(
                              formatCurrency.format(product.price * quantity)),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  Text(
                    'Tổng tiền dự kiến: ${formatCurrency.format(totalAmount)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                  const SizedBox(height: 20),
                  Text('Ghi chú (tùy chọn):',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Yêu cầu thêm của bạn...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Text('Ngày hẹn trả (tùy chọn):',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDueDate == null
                              ? 'Chưa chọn'
                              : 'Ngày ${DateFormat('dd/MM/yyyy').format(_selectedDueDate!)}',
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Chọn ngày'),
                        onPressed: () => _pickDueDate(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ))
                          : const Icon(Icons.assignment_turned_in_outlined),
                      label: Text(isLoading
                          ? 'Đang xử lý...'
                          : 'Xác Nhận Tạo Đơn Công Nợ'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.deepOrangeAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              final itemsPayload =
                                  widget.selectedProducts.map((p) {
                                return {
                                  'product_id': p.id,
                                  'quantity':
                                      widget.selectedQuantities[p.id] ?? 1,
                                };
                              }).toList();

                              context.read<CreateCreditOrderBloc>().add(
                                    SubmitCreditOrder(
                                      items: itemsPayload,
                                      note: _noteController.text.trim(),
                                      dueDate: _selectedDueDate,
                                    ),
                                  );
                            },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
