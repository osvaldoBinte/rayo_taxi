part of 'travelWithTariff_getx.dart';

@immutable
abstract class TravelwithtariffEvent {}

class TravelWithtariffEvent extends TravelwithtariffEvent {
  final ConfirmarTariffEntitie  travel;

  TravelWithtariffEvent({required this.travel});
}
