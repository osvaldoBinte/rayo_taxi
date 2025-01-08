part of 'offerNegotiation_getx.dart';

@immutable
abstract class Offernegotiationevent {}

class OfferNegotiationevent extends Offernegotiationevent {
  final TravelwithtariffEntitie travel;

  OfferNegotiationevent({required this.travel});
}
