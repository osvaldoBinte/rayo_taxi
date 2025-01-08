part of 'get_genders_getx.dart';

@immutable
abstract class GetGendersState {}

class GetGendersInitial extends GetGendersState {}

class GetGendersLoading extends GetGendersState {}

class GetGendersLoaded extends GetGendersState {
  final List<GendersEntities> genders;
  GetGendersLoaded(this.genders);
}

class GetGendersFailure extends GetGendersState {
  final String error;
 GetGendersFailure(this.error);
}
