import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rayo_taxi/features/client/domain/entities/genders_entities.dart';
import 'package:rayo_taxi/features/client/domain/usecases/get_genders_usecase.dart';

part 'get_genders_event.dart';
part 'get_genders_state.dart';

class GetGendersGetx extends GetxController {
  final GetGendersUsecase getGendersUsecase;
  var state = Rx<GetGendersState>(GetGendersInitial());
  var selectedGenderId = Rx<int?>(null); 
  GetGendersGetx(
      {required this.getGendersUsecase});                                                                                 

  fetchCoDetailsGetGenders(FetchgetDetailsEvent fetchSongDetailsEven) async {
    state.value = GetGendersLoading();
    try {
      var getDetails = await getGendersUsecase.execute();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (getDetails.isEmpty) {
          state.value = GetGendersFailure("No hay ningun cliente registrado");
        } else {
          state.value = GetGendersLoaded(getDetails);
        }
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.value = GetGendersFailure(e.toString());
      });
    }
  }
   void setSelectedGender(int? genderId) {
    selectedGenderId.value = genderId;
  }
  
}
