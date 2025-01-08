part of 'rejectTravelOffer_getx.dart';

@immutable
abstract class RejecttravelofferState {}

class RejecttravelofferInitial extends RejecttravelofferState {}

class RejecttravelofferLoading extends RejecttravelofferState {}

class RejecttravelofferSuccessfully extends RejecttravelofferState {}

class RejecttravelofferFailure extends RejecttravelofferState {
  final String error;
  RejecttravelofferFailure(this.error);
}
