import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/qualification/qualification_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/qualification_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/skip_qualification_usecase.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';

class RateTripController extends GetxController {
  final QualificationUsecase qualificationUsecase;

  RateTripController({required this.qualificationUsecase});

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxString _error = ''.obs;
  String get error => _error.value;
  final RxInt rating = 0.obs;
  void updateRating(int value) {
    rating.value = value;
  }

  Future<void> submitRating(TravelAlertModel travel, int rating) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final qualificationEntity = QualificationEntitie(
        qualification: rating,
        id_travel_driver: int.parse(travel.id_travel_driver),
      );

      await qualificationUsecase.execute(qualificationEntity);
      await Get.find<NavigationService>().navigateToHome(selectedIndex: 0);

      CustomSnackBar.showSuccess(
        'Éxito',
        'Gracias por calificar tu viaje',
      );
    } catch (e) {
      Navigator.of(Get.context!).pop();

      _error.value = e.toString();
      CustomSnackBar.showError(
        'Error',
        'No se pudo enviar la calificación',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> skipRating(TravelAlertModel travel) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final qualificationEntity = QualificationEntitie(
        qualification: 0,
        id_travel_driver: int.parse(travel.id_travel_driver),
      );
      await qualificationUsecase.execute(qualificationEntity);

      await Get.find<NavigationService>().navigateToHome(selectedIndex: 0);
    } catch (e) {
      _error.value = e.toString();
      CustomSnackBar.showError(
        'Error',
        'No se pudo omitir la calificación',
      );
      Navigator.of(Get.context!).pop();
    } finally {
      _isLoading.value = false;
    }
  }
}
