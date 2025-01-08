// loginGoogle_state.dart
part of 'loginGoogle_getx.dart';

@immutable
abstract class LogingoogleState {}

class LogingoogleInitial extends LogingoogleState {}

class LogingoogleLoading extends LogingoogleState {}

class LogingoogleSuccessfully extends LogingoogleState {}

class LogingoogleFailure extends LogingoogleState {
  final String error;
  LogingoogleFailure(this.error);
}