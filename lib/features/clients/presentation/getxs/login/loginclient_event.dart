part of 'loginclient_getx.dart';

@immutable
abstract class LoginclientEvent {}

class LoginClientEvent extends LoginclientEvent {
  final Client client;

  LoginClientEvent(this.client);
}
