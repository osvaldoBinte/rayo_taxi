part of 'calculateAge_getx.dart';

@immutable
abstract class CalculateageEvent {}

class CalculateageEvents extends CalculateageEvent {
  final String birthdate;

  CalculateageEvents(this.birthdate);
}
