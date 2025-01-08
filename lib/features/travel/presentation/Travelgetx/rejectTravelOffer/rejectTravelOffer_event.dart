part of 'rejectTravelOffer_getx.dart';

@immutable
abstract class RejecttravelofferEvent {}

class RejectTravelofferEventEvent extends RejecttravelofferEvent {
  final TravelwithtariffEntitie travel;

  RejectTravelofferEventEvent({required this.travel});
}
