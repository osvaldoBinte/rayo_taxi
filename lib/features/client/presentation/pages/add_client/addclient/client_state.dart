part of 'client_getx.dart';

@immutable
abstract class ClientState {}

class ClientInitial extends ClientState {}

class ClientLoading extends ClientState {}

class ClientCreatedSuccessfully extends ClientState {}

class ClientCreationFailure extends ClientState {
  final String error;
  ClientCreationFailure(this.error);
}
