import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/usecases/login_client_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/login_google_usecase.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/custom_alert_dialog.dart';
import 'package:rayo_taxi/features/client/presentation/pages/login_clients_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

part 'loginclient_event.dart';
part 'loginclient_state.dart';

class LoginclientGetx extends GetxController {
  final LoginClientUsecase loginClientUsecase;
  final LoginGoogleUsecase loginGoogleUsecase;

  var state = Rx<LoginclientState>(LoginclientInitial());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );
  var isGoogleLoading = false.obs;

  final RxInt selectedIndex = 0.obs;
  DateTime? lastBackPressTime;
  var isLoading = false.obs;

  LoginclientGetx(
      {required this.loginClientUsecase, required this.loginGoogleUsecase});

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    state.value = LoginclientLoading();
    try {
      final client = Client(email: email, password: password);
      await loginClientUsecase.execute(client);
      state.value = LoginclientSuccessfully();

      Get.offAll(() => HomePage(selectedIndex: 1));
    } catch (e) {
      state.value = LoginclientFailure(e.toString());

      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'ACCESO INCORRECTO',
        text: 'No se pudo iniciar sesión. Inténtalo de nuevo.',
        confirmBtnText: 'OK',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    state.value = LoginclientInitial();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('auth_token');
    });
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      await googleSignIn.signOut();
      print("se cerro la sesion");
    } catch (e) {
      print("Error al cerrar sesión de Google: $e");
    }

    try {
      await googleSignIn.disconnect();
    } catch (e) {
      print("No se pudo revocar el acceso de Google: $e");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    state.value = LoginclientInitial();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('auth_token');
    });
    await prefs.remove('auth_token');

    await Get.offAll(() => LoginClientsPage());
  }

  Future<void> logoutAlert() async {
    showCustomAlert(
      context: Get.context!,
      type: CustomAlertType.confirm,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que deseas cerrar sesión?',
      confirmText: 'Sí',
      cancelText: 'No',
      onConfirm: () async {
        logout();
      },
      onCancel: () {
        Navigator.of(Get.context!).pop();
      },
    );
  }

  Future<bool> handleBackButton() async {
    if (lastBackPressTime == null ||
        DateTime.now().difference(lastBackPressTime!) > Duration(seconds: 2)) {
      lastBackPressTime = DateTime.now();
      Get.showSnackbar(
        GetSnackBar(
          message: 'Presiona nuevamente para salir',
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> loginWithGoogle() async {
    isGoogleLoading.value = true;
    state.value = LoginclientLoading();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state.value = LoginclientFailure('Google sign in cancelled');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Set default birthdate
        final String defaultBirthdate = '00/00/0000';

        final client = Client(
          email: user.email ?? '',
          name: user.displayName ?? '',
          birthdate: defaultBirthdate,
        );

        await loginGoogleUsecase.execute(client);
        state.value = LoginclientSuccessfully();
        Get.offAll(() => HomePage(selectedIndex: 1));
      }
    } catch (e) {
      state.value = LoginclientFailure(e.toString());
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'No se pudo iniciar sesión con Google. Inténtalo de nuevo.',
        confirmBtnText: 'OK',
      );
    } finally {
      isGoogleLoading.value = false;
    }
  }

  Future<String?> _showBirthdateDialog() async {
    final TextEditingController birthdateController = TextEditingController();

    return await Get.dialog<String>(
      AlertDialog(
        title: Text('Fecha de Nacimiento'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Por favor, ingresa tu fecha de nacimiento:'),
              SizedBox(height: 20),
              TextFormField(
                controller: birthdateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Seleccionar fecha',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(0xFFEFC300),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    birthdateController.text =
                        DateFormat('dd/MM/yyyy').format(picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.backgroundColorLogin,
            ),
            child: Text(
              'Continuar',
              style: TextStyle(
                color: Get.theme.colorScheme.textButton,
              ),
            ),
            onPressed: () {
              if (birthdateController.text.isEmpty) {
                QuickAlert.show(
                  context: Get.context!,
                  type: QuickAlertType.error,
                  title: 'Error',
                  text: 'Por favor, selecciona una fecha',
                  confirmBtnText: 'OK',
                );
              } else {
                Get.back(result: birthdateController.text);
              }
            },
          ),
        ],
      ),
    );
  }

  
  Future<void> loginWithApple(
  OAuthCredential credential,
  AuthorizationCredentialAppleID appleCredential,
) async {
  isLoading.value = true;
  state.value = LoginclientLoading();

  try {
    final UserCredential userCredential = 
        await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      // Set default birthdate
      final String defaultBirthdate = '00/00/0000';

      // Construye el nombre completo si está disponible
      String? fullName;
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        fullName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
      }

      final client = Client(
        email: user.email ?? '',
        name: fullName ?? user.displayName ?? '',
        birthdate: defaultBirthdate,
      );

      await loginGoogleUsecase.execute(client); // Puedes reutilizar el mismo usecase o crear uno nuevo
      state.value = LoginclientSuccessfully();
      Get.offAll(() => HomePage(selectedIndex: 1));
    }
  } catch (e) {
    state.value = LoginclientFailure(e.toString());
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error',
      text: 'No se pudo iniciar sesión con Apple. Inténtalo de nuevo.',
      confirmBtnText: 'OK',
    );
  } finally {
    isLoading.value = false;
  }
}
}
