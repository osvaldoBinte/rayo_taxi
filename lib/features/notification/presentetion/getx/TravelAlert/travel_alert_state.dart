part of 'travel_alert_getx.dart';

@immutable
abstract class TravelAlertState {}

class TravelAlertInitial extends TravelAlertState {}

class TravelAlertLoading extends TravelAlertState {}

class TravelAlertLoaded extends TravelAlertState {
  final List<TravelAlertModel> travel;
  TravelAlertLoaded(this.travel);
}

class TravelAlertFailure extends TravelAlertState {
  final String error;
  TravelAlertFailure(this.error);
}
