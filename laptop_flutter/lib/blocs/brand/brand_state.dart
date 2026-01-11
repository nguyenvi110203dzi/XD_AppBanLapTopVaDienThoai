part of 'brand_bloc.dart';

abstract class BrandState extends Equatable {
  const BrandState();

  @override
  List<Object> get props => [];
}

class BrandLoading extends BrandState {}

class BrandLoaded extends BrandState {
  final List<Brand> brands;

  const BrandLoaded({this.brands = const []});

  @override
  List<Object> get props => [brands];
}

class BrandError extends BrandState {
  final String message;

  const BrandError(this.message);

  @override
  List<Object> get props => [message];
}
