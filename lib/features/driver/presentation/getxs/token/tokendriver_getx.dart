import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/domain/usecases/tokendriver_usecase.dart';
part 'tokendriver_event.dart';
part 'tokendriver_state.dart';

class TokendriverGetx extends GetxController {
  final TokendriverUsecase tokendriverUsecase;
  var state = Rx<TokendriverState>(TokendriverInitial());

  TokendriverGetx({required this.tokendriverUsecase});

  Future<void> verifyToken() async {
    state.value = TokendriverLoading();
    try {
      bool isValid = await tokendriverUsecase.execute();
      if (isValid) {
        state.value = TokendriverVerified();
      } else {
        state.value = TokendriverNotVerified();
      }
    } catch (e) {
      state.value = TokendriverFailure(e.toString());
    }
  }
}
