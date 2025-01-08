part of 'calculateAge_getx.dart';

@immutable
abstract class CalculateAgeState {}

class CalculateAgeInitial extends CalculateAgeState {}

class CalculateAgeLoading extends CalculateAgeState {}

class CalculateAgeSuccessfully extends CalculateAgeState {
  final int age;

  CalculateAgeSuccessfully(this.age);
}

class CalculateAgeFailure extends CalculateAgeState {
  final String error;

  CalculateAgeFailure(this.error);
}
