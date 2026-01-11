import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/product.dart';
import '../../repositories/product_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ProductRepository productRepository;

  SearchBloc({required this.productRepository}) : super(SearchInitial()) {
    on<PerformSearch>(_onPerformSearch);
  }

  Future<void> _onPerformSearch(
      PerformSearch event, Emitter<SearchState> emit) async {
    if (event.searchTerm.trim().isEmpty) {
      emit(SearchEmpty()); // Coi như không có kết quả nếu search term rỗng
      return;
    }
    emit(SearchLoading());
    try {
      final results =
          await productRepository.searchProductsByName(event.searchTerm);
      if (results.isEmpty) {
        emit(SearchEmpty());
      } else {
        emit(SearchLoaded(results));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}
