part of 'Update_getx.dart';

@immutable
abstract class UpdateEvent {}

class CreateUpdateEvent extends UpdateEvent {
  final Client client;

  CreateUpdateEvent(this.client);
}
