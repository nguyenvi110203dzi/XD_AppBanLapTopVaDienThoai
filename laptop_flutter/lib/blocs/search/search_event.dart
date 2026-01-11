part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object> get props => [];
}

class PerformSearch extends SearchEvent {
  final String searchTerm;
  const PerformSearch(this.searchTerm);
  @override
  List<Object> get props => [searchTerm];
}
