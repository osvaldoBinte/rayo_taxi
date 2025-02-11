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

  // Método para reiniciar el estado
  void resetState() {
    _isLoading.value = false;
    _error.value = '';
    rating.value = 0;
  }

  void updateRating(int value) {
    rating.value = value;
  }

  Future<void> submitRating(TravelAlertModel travel, int rating) async {
    try {
      if (_isLoading.value) return; // Prevenir múltiples envíos
      
      _isLoading.value = true;
      _error.value = '';

      final qualificationEntity = QualificationEntitie(
        qualification: rating,
        id_travel_driver: int.parse(travel.id_travel_driver),
      );

      await qualificationUsecase.execute(qualificationEntity);
      
      // Asegurarse de que el contexto aún existe antes de cerrar
      if (Get.context != null && Navigator.canPop(Get.context!)) {
        Navigator.of(Get.context!).pop();
      }
      
      await Get.find<NavigationService>().navigateToHome(selectedIndex: 0);

      CustomSnackBar.showSuccess(
        'Éxito',
        'Gracias por calificar tu viaje',
      );
    } catch (e) {
      _error.value = e.toString();
      if (Get.context != null && Navigator.canPop(Get.context!)) {
        Navigator.of(Get.context!).pop();
      }
      CustomSnackBar.showError(
        'Error',
        'No se pudo enviar la calificación',
      );
    } finally {
      _isLoading.value = false;
      resetState(); // Reiniciar el estado después de completar
    }
  }

  Future<void> skipRating(TravelAlertModel travel) async {
    try {
      if (_isLoading.value) return; // Prevenir múltiples envíos
      
      _isLoading.value = true;
      _error.value = '';

      final qualificationEntity = QualificationEntitie(
        qualification: 0,
        id_travel_driver: int.parse(travel.id_travel_driver),
      );
      await qualificationUsecase.execute(qualificationEntity);

      // Asegurarse de que el contexto aún existe antes de cerrar
      if (Get.context != null && Navigator.canPop(Get.context!)) {
        Navigator.of(Get.context!).pop();
      }
      
      await Get.find<NavigationService>().navigateToHome(selectedIndex: 0);
    } catch (e) {
      _error.value = e.toString();
      CustomSnackBar.showError(
        'Error',
        'No se pudo omitir la calificación',
      );
      if (Get.context != null && Navigator.canPop(Get.context!)) {
        Navigator.of(Get.context!).pop();
      }
    } finally {
      _isLoading.value = false;
      resetState(); // Reiniciar el estado después de completar
    }
  }

  @override
  void onClose() {
    resetState();
    super.onClose();
  }
}