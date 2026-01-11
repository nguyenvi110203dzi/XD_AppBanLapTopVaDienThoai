part of 'navigation_bloc.dart'; // Chỉ định file bloc chính

// Lớp trạng thái cho việc điều hướng
class NavigationState extends Equatable {
  final int tabIndex; // Chỉ số của tab đang được chọn

  const NavigationState({required this.tabIndex});

  // Trạng thái khởi tạo
  factory NavigationState.initial() {
    return const NavigationState(tabIndex: 0); // Bắt đầu với tab Home (index 0)
  }

  // Tạo bản sao của trạng thái với thay đổi (nếu có)
  NavigationState copyWith({
    int? tabIndex,
  }) {
    return NavigationState(
      tabIndex: tabIndex ?? this.tabIndex,
    );
  }

  @override
  List<Object> get props => [tabIndex];
}
