part of 'cauhinh_bloc.dart'; // Chỉ định file bloc chính

// Enum định nghĩa các trạng thái có thể có
enum CauHinhStatus { initial, loading, loaded, submitting, success, failure }

class CauHinhState extends Equatable {
  final CauHinhStatus status;
  final List<CauhinhBonho> cauHinhList; // Danh sách các cấu hình
  final List<ProductModel>
      phoneOptions; // Danh sách điện thoại cho ComboBox (Thêm vào đây)
  final String? message; // Thông báo thành công hoặc lỗi

  const CauHinhState({
    this.status = CauHinhStatus.initial,
    this.cauHinhList = const [],
    this.phoneOptions = const [], // Khởi tạo rỗng
    this.message,
  });

  // Hàm copyWith để dễ dàng tạo state mới
  CauHinhState copyWith({
    CauHinhStatus? status,
    List<CauhinhBonho>? cauHinhList,
    List<ProductModel>? phoneOptions, // Thêm vào copyWith
    String? message,
    bool clearMessage = false, // Cờ để xóa message
  }) {
    return CauHinhState(
      status: status ?? this.status,
      cauHinhList: cauHinhList ?? this.cauHinhList,
      phoneOptions: phoneOptions ?? this.phoneOptions, // Cập nhật phoneOptions
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        cauHinhList,
        phoneOptions,
        message
      ]; // Thêm phoneOptions vào props
}
