// lib/bloc/navigation/navigation_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Khai báo các phần của BLoC (event và state)
part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(NavigationState.initial()) {
    // Đặt trạng thái ban đầu
    // Đăng ký xử lý cho sự kiện TabChanged
    on<TabChanged>(_onTabChanged);
  }

  // Hàm xử lý khi sự kiện TabChanged xảy ra
  void _onTabChanged(TabChanged event, Emitter<NavigationState> emit) {
    // Phát ra trạng thái mới với tabIndex được cập nhật
    emit(state.copyWith(tabIndex: event.tabIndex));
  }
}
