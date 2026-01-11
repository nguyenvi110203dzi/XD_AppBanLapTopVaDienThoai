part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {} // Trạng thái ban đầu

class SearchLoading extends SearchState {} // Đang tải kết quả

class SearchLoaded extends SearchState {
  // Tải thành công, có kết quả
  final List<ProductModel> results;
  const SearchLoaded(this.results);
  @override
  List<Object> get props => [results];
}

class SearchEmpty extends SearchState {} // Tải thành công, không có kết quả

class SearchError extends SearchState {
  // Lỗi khi tải
  final String message;
  const SearchError(this.message);
  @override
  List<Object> get props => [message];
}
