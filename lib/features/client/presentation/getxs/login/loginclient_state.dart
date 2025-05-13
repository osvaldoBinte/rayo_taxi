part of '../../pages/login/loginclient_getx.dart';

@immutable
abstract class LoginclientState {}

class LoginclientInitial extends LoginclientState {}

class LoginclientLoading extends LoginclientState {}

class LoginclientSuccessfully extends LoginclientState {}

class LoginclientFailure extends LoginclientState {
  final String error;
  LoginclientFailure(this.error);
}
