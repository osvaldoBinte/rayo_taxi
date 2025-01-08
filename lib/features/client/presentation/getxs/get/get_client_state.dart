part of 'get_client_getx.dart';

@immutable
abstract class GetClientState {}

class GetClientInitial extends GetClientState {}

class GetClientLoading extends GetClientState {}

class GetClientLoaded extends GetClientState {
  final List<ClientModel> client;
  GetClientLoaded(this.client);
}

class GetClientFailure extends GetClientState {
  final String error;
  GetClientFailure(this.error);
}
