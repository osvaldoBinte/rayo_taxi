// loginGoogle_event.dart
part of 'loginGoogle_getx.dart';

@immutable
abstract class LogingoogleEvent {}

class LoginGoogleEvent extends LogingoogleEvent {
  final Client client;

  LoginGoogleEvent({required this.client});
}
