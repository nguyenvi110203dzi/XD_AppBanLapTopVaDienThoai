part of 'banner_management_bloc.dart';

abstract class BannerManagementState extends Equatable {
  const BannerManagementState();

  @override
  List<Object> get props => [];
}

class BannerInitial extends BannerManagementState {}

class BannerLoading extends BannerManagementState {}

class BannerLoadSuccess extends BannerManagementState {
  final List<BannerModel> banners; // Danh sách BannerModel

  const BannerLoadSuccess(this.banners);

  @override
  List<Object> get props => [banners];
}

class BannerLoadFailure extends BannerManagementState {
  final String error;

  const BannerLoadFailure(this.error);

  @override
  List<Object> get props => [error];
}

class BannerOperationInProgress extends BannerManagementState {}

class BannerOperationSuccess extends BannerManagementState {
  final String message;
  const BannerOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class BannerOperationFailure extends BannerManagementState {
  final String error;

  const BannerOperationFailure(this.error);

  @override
  List<Object> get props => [error];
}
