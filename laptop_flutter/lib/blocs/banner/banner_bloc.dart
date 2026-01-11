import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Import đúng Model và Repository
import '../../models/banner.dart'; // Đảm bảo là BannerModel
import '../../repositories/banner_repository.dart';

part 'banner_event.dart';
part 'banner_state.dart';

class BannerBloc extends Bloc<BannerEvent, BannerState> {
  final BannerRepository bannerRepository;

  BannerBloc({required this.bannerRepository}) : super(BannerInitial()) {
    on<LoadBanners>(_onLoadBanners);
  }

  Future<void> _onLoadBanners(
    LoadBanners event,
    Emitter<BannerState> emit,
  ) async {
    try {
      emit(BannerLoading());
      final banners = await bannerRepository.getBanners();
      emit(BannersLoaded(banners)); // Trả về List<BannerModel>
    } catch (e) {
      emit(BannerError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
