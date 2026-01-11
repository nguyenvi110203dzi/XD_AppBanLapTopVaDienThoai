// lib/screens/warehouse_staff/warehouse_import_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/blocs/admin_management/warehouse_management/warehouse_management_bloc.dart';
import 'package:laptop_flutter/models/product.dart';
import 'package:laptop_flutter/repositories/product_repository.dart';

class WarehouseImportScreen extends StatefulWidget {
  const WarehouseImportScreen({super.key});

  @override
  State<WarehouseImportScreen> createState() => _WarehouseImportScreenState();
}

class _WarehouseImportScreenState extends State<WarehouseImportScreen> {
  ProductModel? _selectedProduct;
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<ProductModel> _allProducts = [];
  bool _isLoadingProducts = true;
  String? _productLoadError;

  // Giữ tham chiếu đến BLoC
  late WarehouseManagementBloc _warehouseBloc;

  @override
  void initState() {
    super.initState();
    // Lấy BLoC từ context cha (WarehouseStaffMainScreen)
    _warehouseBloc = context.read<WarehouseManagementBloc>();
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productLoadError = null;
    });
    try {
      // Lấy ProductRepository từ context (đã được cung cấp ở main.dart)
      final products = await RepositoryProvider.of<ProductRepository>(context)
          .getAllProducts();
      if (mounted) {
        // Kiểm tra widget còn mounted không trước khi setState
        setState(() {
          _allProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _productLoadError = 'Lỗi tải danh sách sản phẩm: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_productLoadError!), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitImport() {
    if (!_formKey.currentState!.validate()) {
      return; // Dừng nếu form không hợp lệ
    }

    final quantity = int.tryParse(_quantityController.text);

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn sản phẩm để nhập kho.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Số lượng nhập phải là số nguyên dương.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // Sử dụng _warehouseBloc đã lấy từ initState
    _warehouseBloc.add(ImportStockEvent(
      productId: _selectedProduct!.id,
      quantity: quantity,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WarehouseManagementBloc, WarehouseManagementState>(
      // Nghe state từ BLoC được cung cấp bởi WarehouseStaffMainScreen
      listener: (context, state) {
        if (state is WarehouseOperationSuccess &&
            state.message.contains("Nhập kho")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.green),
          );
          _formKey.currentState?.reset();
          setState(() {
            _selectedProduct = null; // Reset lại lựa chọn sản phẩm
          });
          _quantityController.clear();
          _notesController.clear();
          _loadAllProducts(); // Load lại danh sách sản phẩm để cập nhật số lượng tồn
        } else if (state is WarehouseFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Lỗi Nhập Kho: ${state.error}"),
                backgroundColor: Colors.red),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // Sử dụng ListView để tránh overflow nếu nội dung dài
            children: [
              Text("Chọn Sản Phẩm và Nhập Số Lượng",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (_isLoadingProducts)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_productLoadError != null)
                Center(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(_productLoadError!,
                      style: const TextStyle(
                          color: Colors.red, fontStyle: FontStyle.italic)),
                ))
              else if (_allProducts.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text("Không có sản phẩm nào để nhập kho.",
                      style: TextStyle(color: Colors.grey)),
                ))
              else
                DropdownButtonFormField<ProductModel>(
                  value: _selectedProduct,
                  hint: const Text('Chọn sản phẩm...'),
                  isExpanded: true,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      labelText: "Sản phẩm*",
                      prefixIcon: const Icon(Icons.inventory_2_outlined)),
                  items: _allProducts.map((ProductModel product) {
                    return DropdownMenuItem<ProductModel>(
                      value: product,
                      child: Text(
                          "${product.name} (Hiện có: ${product.quantity})",
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
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                    labelText: 'Số lượng nhập*',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.production_quantity_limits)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số lượng';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) {
                    return 'Số lượng phải là số nguyên dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                    labelText: 'Ghi chú (ví dụ: từ nhà cung cấp ABC)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.notes_outlined)),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              BlocBuilder<WarehouseManagementBloc, WarehouseManagementState>(
                builder: (context, state) {
                  bool isLoading = state
                      is WarehouseLoading; // Chỉ loading khi đang thực hiện thao tác kho
                  return ElevatedButton.icon(
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Icon(Icons.input),
                    label:
                        Text(isLoading ? 'Đang Xử Lý...' : 'Xác Nhận Nhập Kho'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    onPressed: isLoading ? null : _submitImport,
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
