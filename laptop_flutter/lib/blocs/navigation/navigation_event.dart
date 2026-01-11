part of 'navigation_bloc.dart'; // Chỉ định file bloc chính

// Lớp cơ sở cho các sự kiện điều hướng
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

// Sự kiện xảy ra khi người dùng chọn một tab mới
class TabChanged extends NavigationEvent {
  final int tabIndex;

  const TabChanged({required this.tabIndex});

  @override
  List<Object> get props => [tabIndex];
}
