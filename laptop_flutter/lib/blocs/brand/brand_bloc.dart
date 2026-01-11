import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/brand.dart';
import '../../repositories/brand_repository.dart';

part 'brand_event.dart';
part 'brand_state.dart';

class BrandBloc extends Bloc<BrandEvent, BrandState> {
  final BrandRepository brandRepository;

  BrandBloc({required this.brandRepository}) : super(BrandLoading()) {
    on<LoadBrands>(_onLoadBrands);
  }

  Future<void> _onLoadBrands(LoadBrands event, Emitter<BrandState> emit) async {
    emit(BrandLoading());
    try {
      final brands = await brandRepository.getBrands();
      emit(BrandLoaded(brands: brands));
    } catch (e) {
      emit(BrandError(e.toString()));
    }
  }
}
