import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import BLoC, State, Event, Model, Repository

import '../../../blocs/admin_management/thongso_management/cauhinh/cauhinh_bloc.dart';
import '../../../models/cauhinhbonho.dart';
import '../../../models/product.dart'; // Import ProductModel
// Không cần ProductRepository ở đây vì Bloc đã load phoneOptions

class AdminCauHinhAddEditScreen extends StatefulWidget {
  final CauhinhBonho? cauHinhToEdit; // Null nếu là thêm mới
  final List<ProductModel>
      phoneOptions; // Nhận danh sách điện thoại từ màn hình List

  const AdminCauHinhAddEditScreen({
    super.key,
    this.cauHinhToEdit,
    required this.phoneOptions, // Bắt buộc truyền vào
  });

  @override
  State<AdminCauHinhAddEditScreen> createState() =>
      _AdminCauHinhAddEditScreenState();
}

class _AdminCauHinhAddEditScreenState extends State<AdminCauHinhAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.cauHinhToEdit != null;

// Controllers cho các trường spec
  late TextEditingController _hedieuhanhController;
  late TextEditingController _chipCPUController;
  late TextEditingController _tocdoCPUController;
  late TextEditingController _chipDohoaController;
  late TextEditingController _ramController;
  late TextEditingController _dungluongLuutruController;
  late TextEditingController _dungluongKhadungController;
  late TextEditingController _thenhoController;
  late TextEditingController _danhbaController;

// State cho ComboBox sản phẩm
  int? _selectedProductId; // Lưu ID sản phẩm được chọn

  @override
  void initState() {
    super.initState();
// Khởi tạo controllers
    _hedieuhanhController =
        TextEditingController(text: widget.cauHinhToEdit?.hedieuhanh ?? '');
    _chipCPUController =
        TextEditingController(text: widget.cauHinhToEdit?.chipCPU ?? '');
    _tocdoCPUController =
        TextEditingController(text: widget.cauHinhToEdit?.tocdoCPU ?? '');
    _chipDohoaController =
        TextEditingController(text: widget.cauHinhToEdit?.chipDohoa ?? '');
    _ramController =
        TextEditingController(text: widget.cauHinhToEdit?.ram ?? '');
    _dungluongLuutruController = TextEditingController(
        text: widget.cauHinhToEdit?.dungluongLuutru ?? '');
    _dungluongKhadungController = TextEditingController(
        text: widget.cauHinhToEdit?.dungluongKhadung ?? '');
    _thenhoController =
        TextEditingController(text: widget.cauHinhToEdit?.thenho ?? '');
    _danhbaController =
        TextEditingController(text: widget.cauHinhToEdit?.danhba ?? '');

// Gán giá trị ban đầu cho dropdown nếu đang sửa
// Đảm bảo ID sản phẩm cũ vẫn tồn tại trong danh sách options mới nhất
    if (_isEditing &&
        widget.phoneOptions
            .any((p) => p.id == widget.cauHinhToEdit!.idProduct)) {
      _selectedProductId = widget.cauHinhToEdit!.idProduct;
    } else if (_isEditing) {
      print(
          "Warning: Product ID ${widget.cauHinhToEdit!.idProduct} assigned to this spec is no longer available in the phone list.");
// Có thể hiển thị cảnh báo cho admin
    }
  }

  @override
  void dispose() {
// Dispose controllers
    _hedieuhanhController.dispose();
    _chipCPUController.dispose();
    _tocdoCPUController.dispose();
    _chipDohoaController.dispose();
    _ramController.dispose();
    _dungluongLuutruController.dispose();
    _dungluongKhadungController.dispose();
    _thenhoController.dispose();
    _danhbaController.dispose();
    super.dispose();
  }

// Hàm xử lý khi nhấn nút Lưu
  void _handleSave(BuildContext context) {
    final currentState = context.read<CauHinhBloc>().state;
// Không cho lưu nếu đang submitting
    if (currentState.status == CauHinhStatus.submitting) return;

    if (_formKey.currentState!.validate()) {
// Kiểm tra đã chọn sản phẩm chưa (quan trọng khi thêm mới)
      if (_selectedProductId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng chọn sản phẩm để gán cấu hình.'),
              backgroundColor: Colors.orange),
        );
        return;
      }

// Tạo object CauhinhBonho từ controllers VÀ selectedProductId
      final cauHinhData = CauhinhBonho(
        id: widget.cauHinhToEdit?.id ??
            0, // ID cũ nếu sửa, 0 nếu thêm (backend sẽ bỏ qua)
        hedieuhanh: _hedieuhanhController.text.trim(),
        chipCPU: _chipCPUController.text.trim().isNotEmpty
            ? _chipCPUController.text.trim()
            : null,
        tocdoCPU: _tocdoCPUController.text.trim().isNotEmpty
            ? _tocdoCPUController.text.trim()
            : null,
        chipDohoa: _chipDohoaController.text.trim().isNotEmpty
            ? _chipDohoaController.text.trim()
            : null,
        ram: _ramController.text.trim().isNotEmpty
            ? _ramController.text.trim()
            : null,
        dungluongLuutru: _dungluongLuutruController.text.trim().isNotEmpty
            ? _dungluongLuutruController.text.trim()
            : null,
        dungluongKhadung: _dungluongKhadungController.text.trim().isNotEmpty
            ? _dungluongKhadungController.text.trim()
            : null,
        thenho: _thenhoController.text.trim().isNotEmpty
            ? _thenhoController.text.trim()
            : null,
        danhba: _danhbaController.text.trim().isNotEmpty
            ? _danhbaController.text.trim()
            : null,
        idProduct: _selectedProductId!, // Gán ID sản phẩm đã chọn
      );

// Dispatch event tương ứng
      if (_isEditing) {
        context.read<CauHinhBloc>().add(UpdateCauHinh(
            cauHinhId: widget.cauHinhToEdit!.id, cauHinhData: cauHinhData));
      } else {
        context.read<CauHinhBloc>().add(AddCauHinh(cauHinhData));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isEditing ? 'Sửa Cấu hình Bộ nhớ' : 'Thêm Cấu hình Bộ nhớ'),
        actions: [
// Nút lưu
          BlocBuilder<CauHinhBloc, CauHinhState>(builder: (context, state) {
            final isSubmitting = state.status == CauHinhStatus.submitting;
            return IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Lưu',
              onPressed: isSubmitting ? null : () => _handleSave(context),
            );
          }),
        ],
      ),
      body: BlocListener<CauHinhBloc, CauHinhState>(
        listener: (context, state) {
// Tự động pop khi thành công
          if (state.status == CauHinhStatus.success && state.message != null) {
// Hiển thị thông báo thành công trước khi pop
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(state.message!),
                  backgroundColor: Colors.green));
// Đợi một chút để user thấy thông báo rồi mới pop
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                // Kiểm tra lại trước khi pop
                Navigator.of(context).pop(true); // Pop và trả về true
              }
            });
          } else if (state.status == CauHinhStatus.failure &&
              state.message != null) {
// Hiển thị lỗi nếu có
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(state.message!), backgroundColor: Colors.red));
          }
        },
        child: Stack(
          // Stack để hiển thị loading overlay
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
// --- Dropdown chọn Sản phẩm Điện thoại ---
                    _buildSectionTitle('Gán cho Sản phẩm (*)'),
                    DropdownButtonFormField<int>(
                      value: _selectedProductId,
                      hint: const Text('Chọn điện thoại để gán'),
                      isExpanded: true,
// Lấy danh sách options từ widget.phoneOptions
                      items: widget.phoneOptions.map((ProductModel phone) {
                        return DropdownMenuItem<int>(
                          value: phone.id,
                          child: Text('${phone.name} (ID: ${phone.id})',
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedProductId = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn sản phẩm' : null,
                      decoration: _inputDecoration('Điện thoại cần gán *'),
                    ),
                    const SizedBox(height: 20),

// --- Các trường nhập thông số ---
                    _buildSectionTitle('Chi tiết Cấu hình'),
                    _buildTextField(_hedieuhanhController, 'Hệ điều hành',
                        isRequired: true),
                    _buildTextField(_chipCPUController, 'Chip CPU'),
                    _buildTextField(_tocdoCPUController, 'Tốc độ CPU'),
                    _buildTextField(_chipDohoaController, 'Chip đồ họa (GPU)'),
                    _buildTextField(_ramController, 'RAM'),
                    _buildTextField(
                        _dungluongLuutruController, 'Dung lượng lưu trữ'),
                    _buildTextField(
                        _dungluongKhadungController, 'Dung lượng khả dụng'),
                    _buildTextField(_thenhoController, 'Thẻ nhớ ngoài'),
                    _buildTextField(_danhbaController, 'Danh bạ'),
                    const SizedBox(height: 30),

// Nút Lưu
                    Center(
                      child: BlocBuilder<CauHinhBloc, CauHinhState>(
                          builder: (context, state) {
                        final isSubmitting =
                            state.status == CauHinhStatus.submitting;
                        return ElevatedButton.icon(
                          icon: Icon(_isEditing ? Icons.save : Icons.add),
                          label: Text(
                              _isEditing ? 'Lưu thay đổi' : 'Thêm cấu hình'),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15)),
                          onPressed:
                              isSubmitting ? null : () => _handleSave(context),
                        );
                      }),
                    ),
                    const SizedBox(height: 20), // Khoảng trống dưới cùng
                  ],
                ),
              ),
            ),
// --- Loading Overlay khi đang lưu ---
            BlocBuilder<CauHinhBloc, CauHinhState>(builder: (context, state) {
              if (state.status == CauHinhStatus.submitting) {
                return Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Card(
                        margin: EdgeInsets.all(20),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 15),
                              Text("Đang xử lý...")
                            ])),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

// Helper widget để tạo TextFormField
  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label + (isRequired ? ' *' : '')),
        maxLines: maxLines,
        keyboardType:
            maxLines > 1 ? TextInputType.multiline : TextInputType.text,
        validator: isRequired
            ? (value) =>
                (value == null || value.isEmpty) ? 'Vui lòng nhập $label' : null
            : null,
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      ),
    );
  }

// Helper tạo InputDecoration chung
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

// Helper tạo tiêu đề section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent),
      ),
    );
  }
}
