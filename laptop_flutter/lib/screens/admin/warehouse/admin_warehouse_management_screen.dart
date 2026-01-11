// lib/screens/admin/warehouse/admin_warehouse_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:laptop_flutter/blocs/admin_management/warehouse_management/warehouse_management_bloc.dart';
import 'package:laptop_flutter/blocs/auth/auth_bloc.dart';
import 'package:laptop_flutter/models/product.dart';
import 'package:laptop_flutter/models/user.dart';
import 'package:laptop_flutter/repositories/product_repository.dart';

class AdminWarehouseManagementScreen extends StatefulWidget {
  const AdminWarehouseManagementScreen({super.key});

  @override
  State<AdminWarehouseManagementScreen> createState() =>
      _AdminWarehouseManagementScreenState();
}

class _AdminWarehouseManagementScreenState
    extends State<AdminWarehouseManagementScreen> {
  ProductModel? _selectedProductForHistory;
  List<ProductModel> _allProducts = [];
  bool _isLoadingProducts = true;
  String? _loadProductError; // Biến instance, OK
  UserModel? _currentUser;

  late WarehouseManagementBloc _warehouseBloc;

  @override
  void initState() {
    super.initState();
    _warehouseBloc = context.read<WarehouseManagementBloc>();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUser = authState.user;
    }
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    // ... (code không đổi)
    setState(() {
      _isLoadingProducts = true;
      _loadProductError = null;
    });
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
        setState(() {
          _isLoadingProducts = false;
          _loadProductError = "Lỗi tải danh sách sản phẩm: ${e.toString()}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_loadProductError!), backgroundColor: Colors.red),
        );
      }
    }
  }

  // VVV BIẾN THÀNH PHƯƠNG THỨC CỦA LỚP VVV
  Widget _buildOverallQuantityCard() {
    // Bỏ BuildContext context
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tổng Quan Tồn Kho",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark)),
            const SizedBox(height: 12),
            BlocBuilder<WarehouseManagementBloc, WarehouseManagementState>(
              builder: (context, state) {
                // context này là của BlocBuilder
                if (state is WarehouseOverallQuantityLoaded) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tổng SL tất cả sản phẩm:",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        "${state.totalQuantity}",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }
                if (state is WarehouseLoading &&
                    !(state is WarehouseHistoryLoaded)) {
                  return const Center(
                      child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 3)));
                }
                if (state is WarehouseFailure &&
                    !(state is WarehouseOverallQuantityLoaded ||
                        state is WarehouseHistoryLoaded)) {
                  return Text("Lỗi tải tổng số lượng: ${state.error}",
                      style: const TextStyle(
                          color: Colors.red, fontStyle: FontStyle.italic));
                }
                return const Text("Đang tải tổng số lượng...",
                    style: TextStyle(color: Colors.grey));
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text("Làm mới"),
                style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14)),
                onPressed: () {
                  _warehouseBloc.add(LoadOverallQuantityEvent());
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // VVV BIẾN THÀNH PHƯƠNG THỨC CỦA LỚP VVV
  Widget _buildProductHistoryCard() {
    // Bỏ BuildContext context
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Lịch Sử Giao Dịch Kho Sản Phẩm",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark)),
            const SizedBox(height: 16),
            if (_isLoadingProducts) // Sử dụng biến instance trực tiếp
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator()))
            else if (_loadProductError !=
                null) // Sử dụng biến instance trực tiếp
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_loadProductError!,
                    style: const TextStyle(
                        color: Colors.red, fontStyle: FontStyle.italic)),
              )
            else if (_allProducts.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Chưa có sản phẩm nào.")))
            else
              DropdownButtonFormField<ProductModel>(
                value: _selectedProductForHistory,
                hint: const Text('Chọn sản phẩm để xem lịch sử'),
                isExpanded: true,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    labelText: "Sản phẩm",
                    prefixIcon: const Icon(Icons.inventory_2_outlined)),
                items: _allProducts.map((ProductModel product) {
                  return DropdownMenuItem<ProductModel>(
                    value: product,
                    child: Text(product.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (ProductModel? newValue) {
                  setState(() {
                    _selectedProductForHistory = newValue;
                    if (newValue != null) {
                      _warehouseBloc
                          .add(LoadProductStockHistoryEvent(newValue.id));
                    } else {
                      _warehouseBloc.emit(
                          WarehouseHistoryLoaded([], "Vui lòng chọn sản phẩm"));
                    }
                  });
                },
              ),
            const SizedBox(height: 16),
            BlocBuilder<WarehouseManagementBloc, WarehouseManagementState>(
              builder: (context, state) {
                // context này là của BlocBuilder
                if (state is WarehouseLoading &&
                    _selectedProductForHistory != null &&
                    !(state is WarehouseOverallQuantityLoaded)) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (state is WarehouseHistoryLoaded) {
                  if (_selectedProductForHistory == null) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text("Vui lòng chọn một sản phẩm để xem lịch sử.",
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ));
                  }
                  if (state.history.isEmpty) {
                    return Center(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                          "Không có lịch sử giao dịch cho '${state.productName}'.",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 15)),
                    ));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0, top: 8.0),
                        child: Text("Lịch sử cho: ${state.productName}",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.history.length,
                        itemBuilder: (context, index) {
                          // context này của ListView.builder
                          final transaction = state.history[index];
                          final isImport =
                              transaction.transactionType == 'import';
                          final isSale =
                              transaction.transactionType == 'sale_adjustment';
                          final isExportManual =
                              transaction.transactionType == 'export';
                          final DateFormat dateFormat =
                              DateFormat('dd/MM/yyyy HH:mm');

                          Color tileColor = Colors.grey.shade50;
                          IconData leadIcon = Icons.help_outline;
                          Color iconColor = Colors.grey;
                          String titlePrefix = "GIAO DỊCH";

                          if (isImport) {
                            tileColor = Colors.green.shade50;
                            leadIcon = Icons.arrow_circle_down_outlined;
                            iconColor = Colors.green.shade700;
                            titlePrefix = "NHẬP KHO";
                          } else if (isSale) {
                            tileColor = Colors.blue.shade50;
                            leadIcon = Icons.arrow_circle_up_outlined;
                            iconColor = Colors.blue.shade700;
                            titlePrefix = "BÁN HÀNG";
                          } else if (isExportManual) {
                            tileColor = Colors.orange.shade50;
                            leadIcon = Icons.arrow_circle_up_outlined;
                            iconColor = Colors.orange.shade700;
                            titlePrefix = "XUẤT THỦ CÔNG";
                          }

                          return Card(
                            color: tileColor,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              leading:
                                  Icon(leadIcon, color: iconColor, size: 32),
                              title: Text(
                                "$titlePrefix: ${transaction.quantityChange.abs()} sản phẩm",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: iconColor.withOpacity(0.85)),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text(
                                      "Ngày GD: ${dateFormat.format(transaction.transactionDate)}",
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.black87)),
                                  if (transaction.user?.name != null)
                                    Text("Thực hiện: ${transaction.user!.name}",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54)),
                                  if (transaction.orderId != null)
                                    Text("Đơn hàng: #${transaction.orderId}",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54)),
                                  if (transaction.reason != null &&
                                      transaction.reason!.isNotEmpty)
                                    Text("Lý do: ${transaction.reason}",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54)),
                                  if (transaction.notes != null &&
                                      transaction.notes!.isNotEmpty)
                                    Text("Ghi chú: ${transaction.notes}",
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }
                if (state is WarehouseFailure &&
                    _selectedProductForHistory != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text("Lỗi tải lịch sử: ${state.error}",
                        style: const TextStyle(
                            color: Colors.red, fontStyle: FontStyle.italic)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (_currentUser?.role == 1) {
            _warehouseBloc.add(LoadOverallQuantityEvent());
          }
          await _loadAllProducts();
          if (_selectedProductForHistory != null) {
            _warehouseBloc.add(
                LoadProductStockHistoryEvent(_selectedProductForHistory!.id));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_currentUser?.role == 1) ...[
                _buildOverallQuantityCard(), // Gọi như phương thức
                const SizedBox(height: 16),
                _buildProductHistoryCard(), // Gọi như phương thức
              ] else ...[
                const Center(
                    child: Text("Bạn không có quyền truy cập chức năng này.")),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
