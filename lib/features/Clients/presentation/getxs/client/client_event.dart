part of 'client_getx.dart';

@immutable
abstract class ClientEvent {}

class CreateClientEvent extends ClientEvent {
  final Client client;

  CreateClientEvent(this.client);
}
