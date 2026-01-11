import 'dart:io'; // Cho File

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Cho TextInputFormatter
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

// Hoặc dùng package khác như quill_html_editor nếu muốn WYSIWYG editor

// --- Import các file cần thiết ---
import '../../../blocs/admin_management/product_management/product_management_bloc.dart';
import '../../../models/brand.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../repositories/auth_repository.dart'; // Để lấy baseUrl
// ---------------------------------

class AdminAddEditProductScreen extends StatefulWidget {
  final ProductModel? productToEdit; // Sản phẩm cần sửa (null nếu là thêm mới)
  final ProductManagementBloc productManagementBloc;

  const AdminAddEditProductScreen({
    super.key,
    this.productToEdit,
    required this.productManagementBloc,
  });

  @override
  State<AdminAddEditProductScreen> createState() =>
      _AdminAddEditProductScreenState();
}

class _AdminAddEditProductScreenState extends State<AdminAddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers cho các trường text
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _oldPriceController;
  late TextEditingController _quantityController;
  late TextEditingController
      _descriptionController; // Hoặc dùng controller của editor
  late TextEditingController
      _specificationController; // Hoặc dùng controller của editor

  // Biến lưu giá trị Dropdown và ảnh
  Brand? _selectedBrand;
  Category? _selectedCategory;
  XFile? _selectedImageFile;
  String? _existingImageUrl; // Lưu URL ảnh cũ để hiển thị

  List<Brand> _availableBrands = [];
  List<Category> _availableCategories = [];

  // Lấy baseUrl
  late String baseUrl;

  @override
  void initState() {
    super.initState();

    // Lấy baseUrl từ AuthRepository
    baseUrl = context.read<AuthRepository>().baseUrl;

    // Khởi tạo controllers với giá trị của sản phẩm cần sửa (nếu có)
    final product = widget.productToEdit;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    _oldPriceController = TextEditingController(
        text: product?.oldprice?.toString() ?? ''); // Có thể null
    _quantityController =
        TextEditingController(text: product?.quantity.toString() ?? '');
    _descriptionController =
        TextEditingController(text: product?.description ?? '');
    _specificationController =
        TextEditingController(text: product?.specification ?? '');
    _existingImageUrl = product?.image; // Lưu ảnh cũ

    // Lấy danh sách Brands và Categories từ state hiện tại của ProductManagementBloc
    // Điều này yêu cầu ProductManagementLoaded state phải chứa brands và categories
    final blocState = widget.productManagementBloc.state;
    if (blocState is ProductManagementLoaded) {
      _availableBrands = blocState.brands;
      _availableCategories = blocState.categories;

      // Tìm và gán giá trị ban đầu cho Dropdown nếu là chế độ sửa
      if (product != null) {
        try {
          _selectedBrand =
              _availableBrands.firstWhere((b) => b.id == product.brandId);
        } catch (e) {/* Brand không tìm thấy, _selectedBrand sẽ là null */}
        try {
          _selectedCategory = _availableCategories
              .firstWhere((c) => c.id == product.categoryId);
        } catch (e) {
          /* Category không tìm thấy, _selectedCategory sẽ là null */
        }
      }
    } else {
      // Nếu state không phải Loaded (ví dụ lỗi hoặc đang load lại),
      // bạn có thể muốn gọi lại LoadAdminProducts hoặc hiển thị thông báo
      print(
          "Cảnh báo: Không thể lấy danh sách Brand/Category từ ProductManagementBloc state.");
      // Có thể gọi load lại ở đây nếu cần thiết, nhưng cần cẩn thận tránh vòng lặp
      context.read<ProductManagementBloc>().add(LoadAdminProducts());
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _specificationController.dispose();
    super.dispose();
  }

  // Hàm chọn ảnh
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImageFile = image;
      });
    }
  }

  // Hàm submit form
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Kiểm tra Brand và Category đã được chọn chưa
      if (_selectedBrand == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vui lòng chọn thương hiệu'),
            backgroundColor: Colors.red));
        return;
      }
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vui lòng chọn danh mục'),
            backgroundColor: Colors.red));
        return;
      }

      // Parse các giá trị số
      final price = int.tryParse(_priceController.text);
      final oldPrice = _oldPriceController.text.isNotEmpty
          ? int.tryParse(_oldPriceController.text)
          : null;
      final quantity = int.tryParse(_quantityController.text);

      if (price == null || quantity == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Giá và số lượng phải là số hợp lệ'),
            backgroundColor: Colors.red));
        return;
      }

      // Dispatch event đến Bloc
      final bloc = widget.productManagementBloc;
      if (widget.productToEdit == null) {
        // --- Thêm mới ---
        print("Dispatching AddProduct event");

        bloc.add(AddProduct(
          name: _nameController.text.trim(),
          price: price,
          oldprice: oldPrice,
          description: _descriptionController.text.trim(),
          specification: _specificationController.text.trim(),
          quantity: quantity,
          brandId: _selectedBrand!.id,
          categoryId: _selectedCategory!.id,
          imageFile: _selectedImageFile,
        ));
      } else {
        // --- Cập nhật ---
        print(
            "Dispatching UpdateProduct event for ID: ${widget.productToEdit!.id}");
        bloc.add(UpdateProduct(
          productId: widget.productToEdit!.id,
          name: _nameController.text.trim(),
          price: price,
          oldprice: oldPrice,
          description: _descriptionController.text.trim(),
          specification: _specificationController.text.trim(),
          quantity: quantity,
          brandId: _selectedBrand!.id,
          categoryId: _selectedCategory!.id,
          imageFile: _selectedImageFile, // Gửi ảnh mới nếu có
        ));
      }
      // Quay lại màn hình danh sách sau khi gửi event
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Sản phẩm' : 'Thêm Sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Lưu',
            onPressed: _submitForm, // Gọi hàm submit
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Chọn ảnh ---
              _buildImagePicker(),
              const SizedBox(height: 20),

              // --- Tên sản phẩm ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Vui lòng nhập tên sản phẩm'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Giá và Giá cũ ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                          labelText: 'Giá bán',
                          border: OutlineInputBorder(),
                          prefixText: '₫ '),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => (value == null ||
                              value.isEmpty ||
                              int.tryParse(value) == null)
                          ? 'Nhập giá hợp lệ'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _oldPriceController,
                      decoration: const InputDecoration(
                          labelText: 'Giá cũ (nếu có)',
                          border: OutlineInputBorder(),
                          prefixText: '₫ '),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      // Không bắt buộc nhập giá cũ
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            int.tryParse(value) == null) {
                          return 'Nhập số hoặc bỏ trống';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Số lượng ---
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                    labelText: 'Số lượng tồn kho',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => (value == null ||
                        value.isEmpty ||
                        int.tryParse(value) == null)
                    ? 'Nhập số lượng hợp lệ'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- Chọn Thương hiệu (Dropdown) ---
              DropdownButtonFormField<Brand>(
                value: _selectedBrand,
                hint: const Text('Chọn thương hiệu'),
                isExpanded: true, // Cho dropdown chiếm hết chiều rộng
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _availableBrands.map((Brand brand) {
                  return DropdownMenuItem<Brand>(
                    value: brand,
                    child: Text(brand.name),
                  );
                }).toList(),
                onChanged: (Brand? newValue) {
                  setState(() {
                    _selectedBrand = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Vui lòng chọn thương hiệu' : null,
              ),
              const SizedBox(height: 16),

              // --- Chọn Danh mục (Dropdown) ---
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                hint: const Text('Chọn danh mục'),
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _availableCategories.map((Category category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (Category? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Vui lòng chọn danh mục' : null,
              ),
              const SizedBox(height: 16),

              // --- Mô tả (Dùng TextFormField nhiều dòng) ---
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Mô tả sản phẩm',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
                maxLines: 5, // Cho phép nhập nhiều dòng
                keyboardType: TextInputType.multiline,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Vui lòng nhập mô tả'
                    : null,
                // TODO: Cân nhắc dùng HTML Editor nếu cần định dạng phức tạp
              ),
              const SizedBox(height: 16),

              // --- Thông số kỹ thuật (Dùng TextFormField nhiều dòng) ---
              TextFormField(
                controller: _specificationController,
                decoration: const InputDecoration(
                    labelText: 'Thông số kỹ thuật',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Vui lòng nhập thông số'
                    : null,
                // TODO: Cân nhắc dùng HTML Editor
              ),
              const SizedBox(height: 32),
              // Nút lưu đã chuyển lên AppBar
            ],
          ),
        ),
      ),
    );
  }

  // Widget hiển thị và chọn ảnh
  Widget _buildImagePicker() {
    // Xây dựng URL ảnh cũ (nếu có và là đường dẫn tương đối)
    String? fullExistingUrl;
    bool canDisplayNetwork =
        false; // Sử dụng cờ này thay vì kiểm tra fullExistingUrl sau

    // Kiểm tra null HOẶC rỗng ngay từ đầu
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      String imageUrl = _existingImageUrl!;

      if (Uri.tryParse(imageUrl)?.isAbsolute ?? false) {
        fullExistingUrl = imageUrl; // Đã là URL tuyệt đối
        canDisplayNetwork = true;
      } else if (baseUrl.isNotEmpty) {
        // Kiểm tra baseUrl hợp lệ
        final cleanBase = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
        final cleanPath = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
        fullExistingUrl = cleanBase + cleanPath;
        // Kiểm tra tính hợp lệ SAU KHI tạo URL
        canDisplayNetwork = Uri.tryParse(fullExistingUrl)?.isAbsolute ?? false;
        if (!canDisplayNetwork) {
          print("Lỗi tạo URL ảnh cũ: $fullExistingUrl");
          fullExistingUrl = null; // Reset nếu URL không hợp lệ
        }
      } else {
        print("Lỗi: baseUrl rỗng, không thể tạo URL ảnh cũ.");
        // fullExistingUrl vẫn là null, canDisplayNetwork vẫn là false
      }
    } else {
      print(
          "Thông tin: Không có ảnh cũ (_existingImageUrl là null hoặc rỗng).");
    }

    return Center(
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            clipBehavior: Clip.antiAlias,
            child: _selectedImageFile != null
                ? Image.file(
                    File(_selectedImageFile!.path),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) {
                      print("Lỗi hiển thị preview ảnh đã chọn: $e");
                      return const Center(
                          child: Icon(Icons.error_outline, color: Colors.red));
                    },
                  )
                : (fullExistingUrl != null
                    ? Image.network(
                        fullExistingUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print("Lỗi tải ảnh cũ $fullExistingUrl: $error");
                          return const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Colors.grey));
                        },
                      )
                    : const Center(
                        child: Icon(Icons.image_search,
                            size: 50, color: Colors.grey))),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(_selectedImageFile != null ? 'Đổi ảnh' : 'Chọn ảnh'),
            onPressed: _pickImage,
          ),
          if (_selectedImageFile != null)
            TextButton.icon(
              icon: const Icon(Icons.clear, color: Colors.redAccent),
              label: const Text('Bỏ chọn',
                  style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                setState(() {
                  _selectedImageFile = null;
                });
              },
            )
        ],
      ),
    );
  }
}
