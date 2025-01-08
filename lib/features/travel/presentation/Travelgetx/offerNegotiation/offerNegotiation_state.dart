part of 'offerNegotiation_getx.dart';

@immutable
abstract class OffernegotiationState {}

class OffernegotiationInitial extends OffernegotiationState {}

class OffernegotiationLoading extends OffernegotiationState {}

class OffernegotiationSuccessfully extends OffernegotiationState {}

class OffernegotiationFailure extends OffernegotiationState {
  final String error;
  OffernegotiationFailure(this.error);
}
