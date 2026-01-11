part of 'cauhinh_bloc.dart'; // Chỉ định file bloc chính

// Lớp cơ sở trừu tượng cho các sự kiện
abstract class CauHinhEvent extends Equatable {
  const CauHinhEvent();

  @override
  List<Object?> get props => [];
}

// Event tải tất cả các cấu hình đã tạo
class LoadAllCauHinh extends CauHinhEvent {}

// Event thêm một cấu hình mới
class AddCauHinh extends CauHinhEvent {
  final CauhinhBonho
      cauHinhData; // Dữ liệu cấu hình mới (đã bao gồm idProduct từ ComboBox)

  const AddCauHinh(this.cauHinhData);

  @override
  List<Object?> get props => [cauHinhData];
}

// Event cập nhật một cấu hình đã có
class UpdateCauHinh extends CauHinhEvent {
  final int cauHinhId; // ID của cấu hình cần cập nhật
  final CauhinhBonho
      cauHinhData; // Dữ liệu cấu hình mới (đã bao gồm idProduct từ ComboBox)

  const UpdateCauHinh({required this.cauHinhId, required this.cauHinhData});

  @override
  List<Object?> get props => [cauHinhId, cauHinhData];
}

// Event xóa một cấu hình
class DeleteCauHinh extends CauHinhEvent {
  final int cauHinhId;

  const DeleteCauHinh(this.cauHinhId);

  @override
  List<Object?> get props => [cauHinhId];
}
