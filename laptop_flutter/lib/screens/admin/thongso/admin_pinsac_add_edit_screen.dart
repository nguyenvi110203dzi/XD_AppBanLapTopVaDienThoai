import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import BLoC, State, Event, Model, Repository
import '../../../blocs/admin_management/thongso_management/pinsac/pinsac_bloc.dart';
import '../../../models/pinvasac.dart'; // << PinSac model
import '../../../models/product.dart';
// import '../../../repositories/spec_repository.dart'; // Không cần trực tiếp

class AdminPinSacAddEditScreen extends StatefulWidget {
  final PinSac? pinSacToEdit; // Null nếu là thêm mới
  final List<ProductModel> phoneOptions; // Nhận danh sách điện thoại

  const AdminPinSacAddEditScreen({
    super.key,
    this.pinSacToEdit,
    required this.phoneOptions,
  });

  @override
  State<AdminPinSacAddEditScreen> createState() =>
      _AdminPinSacAddEditScreenState();
}

class _AdminPinSacAddEditScreenState extends State<AdminPinSacAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.pinSacToEdit != null;

  // Controllers cho các trường PinSac
  late TextEditingController _dungluongPinController;
  late TextEditingController _loaiPinController;
  late TextEditingController _hotrosacMaxController;
  late TextEditingController _sacTheomayController;
  late TextEditingController _congnghePinController;

  // State cho ComboBox sản phẩm
  int? _selectedProductId;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controllers
    _dungluongPinController =
        TextEditingController(text: widget.pinSacToEdit?.dungluongPin ?? '');
    _loaiPinController =
        TextEditingController(text: widget.pinSacToEdit?.loaiPin ?? '');
    _hotrosacMaxController =
        TextEditingController(text: widget.pinSacToEdit?.hotrosacMax ?? '');
    _sacTheomayController =
        TextEditingController(text: widget.pinSacToEdit?.sacTheomay ?? '');
    _congnghePinController =
        TextEditingController(text: widget.pinSacToEdit?.congnghePin ?? '');

    // Gán giá trị ban đầu cho dropdown nếu đang sửa
    if (_isEditing &&
        widget.phoneOptions
            .any((p) => p.id == widget.pinSacToEdit!.idProduct)) {
      _selectedProductId = widget.pinSacToEdit!.idProduct;
    } else if (_isEditing) {
      print(
          "Warning: Product ID ${widget.pinSacToEdit!.idProduct} assigned to this spec is no longer available in the phone list.");
    }
    // Không cần load phone list ở đây vì đã được truyền vào
  }

  @override
  void dispose() {
    // Dispose controllers
    _dungluongPinController.dispose();
    _loaiPinController.dispose();
    _hotrosacMaxController.dispose();
    _sacTheomayController.dispose();
    _congnghePinController.dispose();
    super.dispose();
  }

  // Hàm xử lý khi nhấn nút Lưu
  void _handleSave(BuildContext context) {
    final currentState = context.read<PinSacBloc>().state;
    if (currentState.status == PinSacStatus.submitting) return;

    if (_formKey.currentState!.validate()) {
      if (_selectedProductId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng chọn sản phẩm để gán thông số.'),
              backgroundColor: Colors.orange),
        );
        return;
      }

      // Tạo object PinSac từ controllers và selectedProductId
      final pinSacData = PinSac(
        id: widget.pinSacToEdit?.id ?? 0,
        dungluongPin: _dungluongPinController.text.trim().isNotEmpty
            ? _dungluongPinController.text.trim()
            : 'N/A',
        loaiPin: _loaiPinController.text.trim().isNotEmpty
            ? _loaiPinController.text.trim()
            : null,
        hotrosacMax: _hotrosacMaxController.text.trim().isNotEmpty
            ? _hotrosacMaxController.text.trim()
            : null,
        sacTheomay: _sacTheomayController.text.trim().isNotEmpty
            ? _sacTheomayController.text.trim()
            : null,
        congnghePin: _congnghePinController.text.trim().isNotEmpty
            ? _congnghePinController.text.trim()
            : null,
        idProduct: _selectedProductId!,
      );

      // Dispatch event tương ứng
      if (_isEditing) {
        context.read<PinSacBloc>().add(UpdatePinSac(
            pinSacId: widget.pinSacToEdit!.id,
            pinSacData: pinSacData)); // << UpdatePinSac
      } else {
        context.read<PinSacBloc>().add(AddPinSac(pinSacData)); // << AddPinSac
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEditing ? 'Sửa Pin & Sạc' : 'Thêm Pin & Sạc'), // << Đổi tiêu đề
        actions: [
          BlocBuilder<PinSacBloc, PinSacState>(// << PinSacBloc
              builder: (context, state) {
            final isSubmitting = state.status == PinSacStatus.submitting;
            return IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Lưu',
              onPressed: isSubmitting ? null : () => _handleSave(context),
            );
          }),
        ],
      ),
      body: BlocListener<PinSacBloc, PinSacState>(
        // << PinSacBloc
        listener: (context, state) {
          if (state.status == PinSacStatus.success) {
            Navigator.of(context).pop(true);
          } else if (state.status == PinSacStatus.failure &&
              state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(state.message!), backgroundColor: Colors.red));
          }
        },
        child: Stack(
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

                    // --- Các trường nhập thông số Pin & Sạc ---
                    _buildSectionTitle('Chi tiết Pin & Sạc'),
                    _buildTextField(_dungluongPinController, 'Dung lượng pin',
                        isRequired: true),
                    _buildTextField(_loaiPinController, 'Loại pin'),
                    _buildTextField(
                        _hotrosacMaxController, 'Hỗ trợ sạc tối đa'),
                    _buildTextField(_sacTheomayController, 'Sạc kèm theo máy'),
                    _buildTextField(_congnghePinController, 'Công nghệ pin'),
                    const SizedBox(height: 30),

                    // Nút Lưu
                    Center(
                      child:
                          BlocBuilder<PinSacBloc, PinSacState>(// << PinSacBloc
                              builder: (context, state) {
                        final isSubmitting =
                            state.status == PinSacStatus.submitting;
                        return ElevatedButton.icon(
                          icon: Icon(_isEditing ? Icons.save : Icons.add),
                          label: Text(
                              _isEditing ? 'Lưu thay đổi' : 'Thêm thông số'),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15)),
                          onPressed:
                              isSubmitting ? null : () => _handleSave(context),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // --- Loading Overlay khi đang lưu ---
            BlocBuilder<PinSacBloc, PinSacState>(// << PinSacBloc
                builder: (context, state) {
              if (state.status == PinSacStatus.submitting) {
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

  // Helper widget tạo TextFormField
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
            color: Colors.deepPurple), // Đổi màu tiêu đề
      ),
    );
  }
}
