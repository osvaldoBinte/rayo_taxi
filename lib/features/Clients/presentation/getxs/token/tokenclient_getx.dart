import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:rayo_taxi/features/Clients/domain/entities/client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/usecases/tokenclient_usecase.dart';
import '../../pages/login_clients_page.dart';
part 'tokenclient_event.dart';
part 'tokenclient_state.dart';


class TokenclientGetx extends GetxController {
  final TokenclientUsecase tokenclientUsecase;
  var state = Rx<TokenclientState>(TokenclientInitial());

  TokenclientGetx({required this.tokenclientUsecase});

  Future<void> verifyToken() async {
    state.value = TokenclientLoading();
    try {
      bool isValid = await tokenclientUsecase.execute();
      if (isValid) {
        state.value = TokenclientVerified();
      } else {
        state.value = TokenclientNotVerified();
      }
    } catch (e) {
      state.value = TokenclientFailure(e.toString());
    }
  }
}
