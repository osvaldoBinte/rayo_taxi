import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/client/data/models/client_model.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/usecases/get_client_usecase.dart';

import '../../../../AuthS/connectivity_service.dart';
part 'get_client_event.dart';
part 'get_client_state.dart';

class GetClientGetx extends GetxController {
  final GetClientUsecase getClientUsecase;
  var state = Rx<GetClientState>(GetClientInitial());
  final ConnectivityService connectivityService;

  GetClientGetx(
      {required this.getClientUsecase, required this.connectivityService});                                                                                 

  fetchCoDetails(FetchgetDetailsEvent fetchSongDetailsEvent) async {
    state.value = GetClientLoading();
    try {
      bool isConnected = connectivityService.isConnected;
      var getDetails = await getClientUsecase.execute(isConnected);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (getDetails.isEmpty) {
          state.value = GetClientFailure("No hay ningun cliente registrado");
        } else {
          state.value = GetClientLoaded(getDetails);
        }
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.value = GetClientFailure(e.toString());
      });
    }
  }
}
