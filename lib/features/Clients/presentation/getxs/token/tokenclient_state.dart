part of 'tokenclient_getx.dart';

@immutable
abstract class TokenclientState {}

class TokenclientInitial extends TokenclientState {}

class TokenclientLoading extends TokenclientState {}

class TokenclientVerified extends TokenclientState {}

class TokenclientNotVerified extends TokenclientState {}

class TokenclientFailure extends TokenclientState {
  final String error;
  TokenclientFailure(this.error);
}
