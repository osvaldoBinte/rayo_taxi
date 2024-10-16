import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/connectivity_service.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel_alert_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travels_alert_usecase.dart';

part 'travel_alert_event.dart';
part 'travel_alert_state.dart';

class TravelAlertGetx extends GetxController {
  final TravelAlertUsecase travelAlertUsecase;
  var state = Rx<TravelAlertState>(TravelAlertInitial());
  final ConnectivityService connectivityService;

  TravelAlertGetx(
      {required this.travelAlertUsecase, required this.connectivityService});                                                                                 

  fetchCoDetails(FetchgetDetailsEvent fetchSongDetailsEvent) async {
    state.value = TravelAlertLoading();
    try {
      bool isConnected = connectivityService.isConnected;
      var getDetails = await travelAlertUsecase.execute(isConnected);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (getDetails.isEmpty) {
          state.value = TravelAlertFailure("No hay ningun viaje  registrado");
        } else {
          state.value = TravelAlertLoaded(getDetails);
        }
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.value = TravelAlertFailure(e.toString());
      });
    }
  }
}
