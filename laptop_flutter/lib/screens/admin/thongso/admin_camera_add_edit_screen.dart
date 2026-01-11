import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import BLoC, State, Event, Model, Repository
import '../../../blocs/admin_management/thongso_management/camera/camera_bloc.dart';
import '../../../models/cameramanhinh.dart'; // << CameraManhinh model
import '../../../models/product.dart';
// import '../../../repositories/spec_repository.dart'; // Không cần trực tiếp ở đây

class AdminCameraAddEditScreen extends StatefulWidget {
  final CameraManhinh? cameraToEdit; // Null nếu là thêm mới
  final List<ProductModel> phoneOptions; // Nhận danh sách điện thoại

  const AdminCameraAddEditScreen({
    super.key,
    this.cameraToEdit,
    required this.phoneOptions,
  });

  @override
  State<AdminCameraAddEditScreen> createState() =>
      _AdminCameraAddEditScreenState();
}

class _AdminCameraAddEditScreenState extends State<AdminCameraAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.cameraToEdit != null;

  // Controllers cho các trường CameraManhinh
  late TextEditingController _dophangiaiCamsauController;
  late TextEditingController _congngheCamsauController;
  late TextEditingController _tinhnangCamsauController;
  late TextEditingController _dophangiaiCamtruocController;
  late TextEditingController _tinhnangCamtruocController;
  late TextEditingController _congngheManhinhController;
  late TextEditingController _dophangiaiManhinhController;
  late TextEditingController _rongManhinhController;
  late TextEditingController _dosangManhinhController;
  late TextEditingController _matkinhManhinhController;
  bool? _denflashCamsauValue; // Checkbox state

  // State cho ComboBox sản phẩm
  int? _selectedProductId;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controllers
    _dophangiaiCamsauController = TextEditingController(
        text: widget.cameraToEdit?.dophangiaiCamsau ?? '');
    _congngheCamsauController =
        TextEditingController(text: widget.cameraToEdit?.congngheCamsau ?? '');
    _tinhnangCamsauController =
        TextEditingController(text: widget.cameraToEdit?.tinhnangCamsau ?? '');
    _dophangiaiCamtruocController = TextEditingController(
        text: widget.cameraToEdit?.dophangiaiCamtruoc ?? '');
    _tinhnangCamtruocController = TextEditingController(
        text: widget.cameraToEdit?.tinhnangCamtruoc ?? '');
    _congngheManhinhController =
        TextEditingController(text: widget.cameraToEdit?.congngheManhinh ?? '');
    _dophangiaiManhinhController = TextEditingController(
        text: widget.cameraToEdit?.dophangiaiManhinh ?? '');
    _rongManhinhController =
        TextEditingController(text: widget.cameraToEdit?.rongManhinh ?? '');
    _dosangManhinhController =
        TextEditingController(text: widget.cameraToEdit?.dosangManhinh ?? '');
    _matkinhManhinhController =
        TextEditingController(text: widget.cameraToEdit?.matkinhManhinh ?? '');
    _denflashCamsauValue =
        widget.cameraToEdit?.denflashCamsau; // Gán giá trị bool ban đầu

    // Gán giá trị ban đầu cho dropdown nếu đang sửa
    if (_isEditing &&
        widget.phoneOptions
            .any((p) => p.id == widget.cameraToEdit!.idProduct)) {
      _selectedProductId = widget.cameraToEdit!.idProduct;
    } else if (_isEditing) {
      print(
          "Warning: Product ID ${widget.cameraToEdit!.idProduct} assigned to this spec is no longer available in the phone list.");
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _dophangiaiCamsauController.dispose();
    _congngheCamsauController.dispose();
    _tinhnangCamsauController.dispose();
    _dophangiaiCamtruocController.dispose();
    _tinhnangCamtruocController.dispose();
    _congngheManhinhController.dispose();
    _dophangiaiManhinhController.dispose();
    _rongManhinhController.dispose();
    _dosangManhinhController.dispose();
    _matkinhManhinhController.dispose();
    super.dispose();
  }

  // Hàm xử lý khi nhấn nút Lưu
  void _handleSave(BuildContext context) {
    final currentState = context.read<CameraBloc>().state;
    if (currentState.status == CameraStatus.submitting) return;

    if (_formKey.currentState!.validate()) {
      if (_selectedProductId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng chọn sản phẩm để gán thông số.'),
              backgroundColor: Colors.orange),
        );
        return;
      }

      // Tạo object CameraManhinh từ controllers và selectedProductId
      final cameraData = CameraManhinh(
        id: widget.cameraToEdit?.id ?? 0,
        dophangiaiCamsau: _dophangiaiCamsauController.text.trim().isNotEmpty
            ? _dophangiaiCamsauController.text.trim()
            : 'N/A',
        congngheCamsau: _congngheCamsauController.text.trim().isNotEmpty
            ? _congngheCamsauController.text.trim()
            : null,
        denflashCamsau: _denflashCamsauValue,
        tinhnangCamsau: _tinhnangCamsauController.text.trim().isNotEmpty
            ? _tinhnangCamsauController.text.trim()
            : null,
        dophangiaiCamtruoc: _dophangiaiCamtruocController.text.trim().isNotEmpty
            ? _dophangiaiCamtruocController.text.trim()
            : null,
        tinhnangCamtruoc: _tinhnangCamtruocController.text.trim().isNotEmpty
            ? _tinhnangCamtruocController.text.trim()
            : null,
        congngheManhinh: _congngheManhinhController.text.trim().isNotEmpty
            ? _congngheManhinhController.text.trim()
            : null,
        dophangiaiManhinh: _dophangiaiManhinhController.text.trim().isNotEmpty
            ? _dophangiaiManhinhController.text.trim()
            : null,
        rongManhinh: _rongManhinhController.text.trim().isNotEmpty
            ? _rongManhinhController.text.trim()
            : null,
        dosangManhinh: _dosangManhinhController.text.trim().isNotEmpty
            ? _dosangManhinhController.text.trim()
            : null,
        matkinhManhinh: _matkinhManhinhController.text.trim().isNotEmpty
            ? _matkinhManhinhController.text.trim()
            : null,
        idProduct: _selectedProductId!,
      );

      // Dispatch event tương ứng
      if (_isEditing) {
        context.read<CameraBloc>().add(UpdateCamera(
            cameraId: widget.cameraToEdit!.id,
            cameraData: cameraData)); // << UpdateCamera
      } else {
        context.read<CameraBloc>().add(AddCamera(cameraData)); // << AddCamera
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Sửa Camera/Màn hình'
            : 'Thêm Camera/Màn hình'), // << Đổi tiêu đề
        actions: [
          BlocBuilder<CameraBloc, CameraState>(// << CameraBloc
              builder: (context, state) {
            final isSubmitting = state.status == CameraStatus.submitting;
            return IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Lưu',
              onPressed: isSubmitting ? null : () => _handleSave(context),
            );
          }),
        ],
      ),
      body: BlocListener<CameraBloc, CameraState>(
        // << CameraBloc
        listener: (context, state) {
          if (state.status == CameraStatus.success) {
            Navigator.of(context).pop(true);
          } else if (state.status == CameraStatus.failure &&
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

                    // --- Các trường nhập thông số Camera ---
                    _buildSectionTitle('Thông số Camera'),
                    _buildTextField(
                        _dophangiaiCamsauController, 'Độ phân giải camera sau',
                        isRequired: true),
                    _buildTextField(
                        _congngheCamsauController, 'Công nghệ camera sau'),
                    CheckboxListTile(
                      title: const Text('Có đèn Flash sau'),
                      value: _denflashCamsauValue ?? false,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _denflashCamsauValue = newValue;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    _buildTextField(
                        _tinhnangCamsauController, 'Tính năng camera sau',
                        maxLines: 3),
                    _buildTextField(_dophangiaiCamtruocController,
                        'Độ phân giải camera trước'),
                    _buildTextField(
                        _tinhnangCamtruocController, 'Tính năng camera trước',
                        maxLines: 3),
                    const SizedBox(height: 20),

                    // --- Các trường nhập thông số Màn hình ---
                    _buildSectionTitle('Thông số Màn hình'),
                    _buildTextField(
                        _congngheManhinhController, 'Công nghệ màn hình'),
                    _buildTextField(
                        _dophangiaiManhinhController, 'Độ phân giải màn hình'),
                    _buildTextField(_rongManhinhController, 'Màn hình rộng'),
                    _buildTextField(_dosangManhinhController, 'Độ sáng tối đa'),
                    _buildTextField(
                        _matkinhManhinhController, 'Mặt kính cảm ứng'),
                    const SizedBox(height: 30),

                    // Nút Lưu
                    Center(
                      child:
                          BlocBuilder<CameraBloc, CameraState>(// << CameraBloc
                              builder: (context, state) {
                        final isSubmitting =
                            state.status == CameraStatus.submitting;
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
            BlocBuilder<CameraBloc, CameraState>(// << CameraBloc
                builder: (context, state) {
              if (state.status == CameraStatus.submitting) {
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
            color: Colors.blueAccent),
      ),
    );
  }
}
