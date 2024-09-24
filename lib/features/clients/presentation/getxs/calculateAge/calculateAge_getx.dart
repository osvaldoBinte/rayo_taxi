import 'package:meta/meta.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/calculate_age_usecase.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/create_client_usecase.dart';

part 'calculateAge_event.dart';
part 'calculateAge_state.dart';
class CalculateAgeGetx extends GetxController {
  final CalculateAgeUsecase calculateAgeUsecase;

  var state = Rx<CalculateAgeState>(CalculateAgeInitial());

  CalculateAgeGetx({required this.calculateAgeUsecase});

  void calculateAge(String birthdate) async {
    state.value = CalculateAgeLoading();
    try {
      final age = calculateAgeUsecase.execute(birthdate);
      state.value = CalculateAgeSuccessfully(age);
    } catch (e) {
      state.value = CalculateAgeFailure(e.toString());
    }
  }
}