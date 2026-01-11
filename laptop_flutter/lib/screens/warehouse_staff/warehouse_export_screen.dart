// lib/screens/warehouse_staff/warehouse_export_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/blocs/admin_management/warehouse_management/warehouse_management_bloc.dart';
import 'package:laptop_flutter/models/product.dart';
import 'package:laptop_flutter/repositories/product_repository.dart';

class WarehouseExportScreen extends StatefulWidget {
  const WarehouseExportScreen({super.key});

  @override
  State<WarehouseExportScreen> createState() => _WarehouseExportScreenState();
}

class _WarehouseExportScreenState extends State<WarehouseExportScreen> {
  ProductModel? _selectedProduct;
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController(); // Lý do xuất
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<ProductModel> _allProducts = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await RepositoryProvider.of<ProductRepository>(context)
          .getAllProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tải danh sách sản phẩm: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitExport() {
    if (_formKey.currentState!.validate()) {
      final quantity = int.tryParse(_quantityController.text);
      if (_selectedProduct != null && quantity != null && quantity > 0) {
        if (_selectedProduct!.quantity < quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Số lượng tồn kho không đủ để xuất.'),
                backgroundColor: Colors.red),
          );
          return;
        }
        context.read<WarehouseManagementBloc>().add(ExportStockEvent(
              productId: _selectedProduct!.id,
              quantity: quantity,
              reason: _reasonController.text.trim(),
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng chọn sản phẩm và nhập số lượng hợp lệ.'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WarehouseManagementBloc, WarehouseManagementState>(
      listener: (context, state) {
        if (state is WarehouseOperationSuccess &&
            state.message.contains("Xuất kho")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.green),
          );
          _formKey.currentState?.reset();
          setState(() {
            _selectedProduct = null;
          });
          _quantityController.clear();
          _reasonController.clear();
          _notesController.clear();
          _loadAllProducts(); // Load lại để cập nhật số lượng tồn
        } else if (state is WarehouseFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_isLoadingProducts)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<ProductModel>(
                  value: _selectedProduct,
                  hint: const Text('Chọn sản phẩm để xuất kho'),
                  isExpanded: true,
                  items: _allProducts.map((ProductModel product) {
                    return DropdownMenuItem<ProductModel>(
                      value: product,
                      child: Text("${product.name} (Tồn: ${product.quantity})",
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (ProductModel? newValue) {
                    setState(() {
                      _selectedProduct = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Vui lòng chọn sản phẩm' : null,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Sản phẩm*"),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                    labelText: 'Số lượng xuất*', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Vui lòng nhập số lượng';
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) return 'Số lượng phải lớn hơn 0';
                  if (_selectedProduct != null &&
                      n > _selectedProduct!.quantity) {
                    return 'Số lượng xuất không thể lớn hơn tồn kho (${_selectedProduct!.quantity})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                    labelText: 'Lý do xuất kho*', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Vui lòng nhập lý do xuất'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                    labelText: 'Ghi chú (nếu có)',
                    border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              BlocBuilder<WarehouseManagementBloc, WarehouseManagementState>(
                builder: (context, state) {
                  bool isLoading = state is WarehouseLoading;
                  return ElevatedButton.icon(
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ))
                        : const Icon(Icons.output),
                    label:
                        Text(isLoading ? 'Đang xử lý...' : 'Xác Nhận Xuất Kho'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16)),
                    onPressed: isLoading ? null : _submitExport,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
