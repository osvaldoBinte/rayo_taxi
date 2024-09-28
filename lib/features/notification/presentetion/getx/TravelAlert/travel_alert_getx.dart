import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/data/models/client_model.dart';
import 'package:rayo_taxi/features/clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/clients/domain/usecases/get_client_usecase.dart';
import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/notification/domain/usecases/travel_alert_usecase.dart';
import 'package:rayo_taxi/features/notification/domain/usecases/travels_alert_usecase.dart';

import '../../../../../connectivity_service.dart';
part 'travel_alert_event.dart';
part 'travel_alert_state.dart';

class TravelAlertGetx extends GetxController {
  final TravelAlertUsecase travelAlertUsecase;
  var state = Rx<TravelAlertState>(TravelAlertInitial());
  final ConnectivityService connectivityService;

  TravelAlertGetx(
      {required this.travelAlertUsecase, required this.connectivityService});                                                                                 

  fetchCoDetails(FetchgetDetailsssEvent fetchSongDetailsEvent) async {
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
