import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/client/data/models/client_model.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/usecases/get_client_usecase.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/current_travel_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/travels_alert_usecase.dart';

import '../../../../AuthS/connectivity_service.dart';
part 'travel_alert_event.dart';
part 'travel_alert_state.dart';

class CurrentTravelGetx extends GetxController {
  final CurrentTravelUsecase currentTravelUsecase;
  var state = Rx<TravelAlertState>(TravelAlertInitial());
  final ConnectivityService connectivityService;

 CurrentTravelGetx(
      {required this.currentTravelUsecase, required this.connectivityService});                                                                                 

  fetchCoDetails(FetchgetDetailsssEvent fetchSongDetailsEvent) async {
    state.value = TravelAlertLoading();
    try {
      bool isConnected = connectivityService.isConnected;
      var getDetails = await currentTravelUsecase.execute();
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