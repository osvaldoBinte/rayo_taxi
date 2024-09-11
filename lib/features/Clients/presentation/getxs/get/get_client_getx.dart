import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/Clients/data/models/client_model.dart';
import 'package:rayo_taxi/features/Clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/Clients/domain/usecases/get_client_usecase.dart';
part 'get_client_event.dart';
part 'get_client_state.dart';

class GetClientGetx extends GetxController {
  final GetClientUsecase getClientUsecase;
  var state = Rx<GetClientState>(GetClientInitial());

  GetClientGetx({required this.getClientUsecase});
  @override
  void onInit() {
    super.onInit();
    fetchCoDetails(FetchgetDetailsEvent());
  }

  fetchCoDetails(FetchgetDetailsEvent fetchSongDetailsEvent) async {
    state.value = GetClientLoading();
    try {
      var getDetails = await getClientUsecase.execute();
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
