part of 'Update_getx.dart';

@immutable
abstract class UpdateState {}

class UpdateInitial extends UpdateState {}

class UpdateLoading extends UpdateState {}

class UpdateCreatedSuccessfully extends UpdateState {}

class UpdateCreationFailure extends UpdateState {
  final String error;
  UpdateCreationFailure(this.error);
}
