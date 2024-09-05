part of 'tokendriver_getx.dart';

@immutable
abstract class TokendriverState {}

class TokendriverInitial extends TokendriverState {}

class TokendriverLoading extends TokendriverState {}

class TokendriverVerified extends TokendriverState {}

class TokendriverNotVerified extends TokendriverState {}

class TokendriverFailure extends TokendriverState {
  final String error;
  TokendriverFailure(this.error);
}
