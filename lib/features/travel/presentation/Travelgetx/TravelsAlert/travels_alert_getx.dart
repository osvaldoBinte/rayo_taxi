import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/client/data/models/client_model.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/usecases/get_client_usecase.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/travels_alert_usecase.dart';

import '../../../../AuthS/connectivity_service.dart';
part 'travels_alert_event.dart';
part 'travels_alert_state.dart';

class TravelsAlertGetx extends GetxController {
  final TravelsAlertUsecase travelsAlertUsecase;
  var state = Rx<TravelsAlertState>(TravelsAlertInitial());
  final ConnectivityService connectivityService;

  TravelsAlertGetx(
      {required this.travelsAlertUsecase, required this.connectivityService});                                                                                 

  fetchCoDetails(FetchtravelsDetailsEvent fetchSongDetailsEvent) async {
    state.value = TravelsAlertLoading();
    try {
      bool isConnected = connectivityService.isConnected;
      var getDetails = await travelsAlertUsecase.execute(isConnected);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (getDetails.isEmpty) {
          state.value = TravelsAlertFailure("No hay ningun viaje  registrado");
        } else {
          state.value = TravelsAlertLoaded(getDetails);
        }
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.value = TravelsAlertFailure(e.toString());
      });
    }
  }
}
