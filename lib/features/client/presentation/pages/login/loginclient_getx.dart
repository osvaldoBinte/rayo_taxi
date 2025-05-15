import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/domain/usecases/login_client_usecase.dart';
import 'package:rayo_taxi/features/client/domain/usecases/login_google_usecase.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/update/Update_getx.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/travel/id_device_usecase.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/custom_alert_dialog.dart';
import 'package:rayo_taxi/features/client/presentation/pages/login/login_clients_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:io' show Platform;
part '../../getxs/login/loginclient_event.dart';
part '../../getxs/login/loginclient_state.dart';

class LoginclientGetx extends GetxController {
  final LoginClientUsecase loginClientUsecase;
  final LoginGoogleUsecase loginGoogleUsecase;
  final IdDeviceUsecase idDeviceUsecase;
     FirebaseMessaging messaging = FirebaseMessaging.instance;

  var isGoogleSignInAvailable = false.obs;

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
      {required this.loginClientUsecase, required this.loginGoogleUsecase,required this.idDeviceUsecase});
 @override
  void onInit() {
    super.onInit();
    checkGoogleSignInAvailability();
  }Future<void> checkGoogleSignInAvailability() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
    );

    if (Platform.isIOS) {
      try {
        final bool? isInstalled = await googleSignIn.isSignedIn();
        isGoogleSignInAvailable.value = isInstalled ?? false;
      } catch (e) {
        print('Google Sign-In check failed: $e');
        isGoogleSignInAvailable.value = false;
      }
    } else {
      try {
        await googleSignIn.clientId;
        isGoogleSignInAvailable.value = true;
        print('Google Sign-In appears to be available on Android');
      } catch (e) {
        String errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains("sign_in_required") || 
            errorMsg.contains("not signed in") ||
            errorMsg.contains("sign in required")) {
          isGoogleSignInAvailable.value = true;
          print('User not signed in, but Google services seem available');
        } else {
          print('Google Sign-In availability check error: $e');
          isGoogleSignInAvailable.value = false;
        }
      }
    }
  } catch (e) {
    print('Google Sign-In availability check error: $e');
    isGoogleSignInAvailable.value = false;
  }
}
 Future<void> login(String email, String password) async {
   
  isLoading.value = true;
  state.value = LoginclientLoading();
  try {
    final client = Client(email: email, password: password);
    await loginClientUsecase.execute(client);
    String? tokenDevice = await messaging.getToken();
    print('Device Token: $tokenDevice');
    final updateGetx = Get.find<UpdateGetx>();
    updateGetx.isPasswordAuthProvider.value = true;
    idDeviceUsecase.execute(tokenDevice);
    state.value = LoginclientSuccessfully();
    Get.offAll(() => HomePage(selectedIndex: 1));
  } catch (e) {
    state.value = LoginclientFailure(e.toString());
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'ACCESO INCORRECTO',
      text: 'No se pudo iniciar sesión. Inténtalo de nuevo. $e',
      confirmBtnText: 'OK',
    );
  } finally {
    isLoading.value = false;
  }
}
Future<void> logout() async {
  state.value = LoginclientInitial();
  
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    try {
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      }
    } catch (e) {
      print("Error durante el cierre de sesión de Google: $e");
    }
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    Get.find<UpdateGetx>().isPasswordAuthProvider.value = false;
    
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("Error al cerrar sesión de Firebase: $e");
    }
    
    await Get.offAll(() => LoginClientsPage());
  } catch (e) {
    print("Error durante el logout: $e");
    await Get.offAll(() => LoginClientsPage());
  }
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
    if (!isGoogleSignInAvailable.value) {
    // Use GetX snackbar instead of QuickAlert for more flexibility
    Get.snackbar(
      'Error', 
      'Inicio de sesión con Google no disponible en este dispositivo.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return;
  }
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
        String? tokenDevice = await messaging.getToken();
    print('Device Token: $tokenDevice');
    idDeviceUsecase.execute(tokenDevice);
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

  

Future<void> loginWithApple() async {
  isLoading.value = true;
  state.value = LoginclientLoading();
  
  try {
    // Check if Sign In with Apple is available
    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw SignInWithAppleNotSupportedException(
        message: 'Sign In with Apple is not available on this device',
      );
    }

    // Generar un nonce aleatorio seguro para la autenticación
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);
    
    // Solicitar las credenciales de Apple
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    
    print('Apple Credential Details:');
    print('Identity Token: ${appleCredential.identityToken}');
    print('Authorization Code: ${appleCredential.authorizationCode}');
    print('User Identifier: ${appleCredential.userIdentifier}');
    print('Raw Nonce: $rawNonce');
    print('Processed Nonce: $nonce');
    
    // Validate credentials before Firebase auth
    if (appleCredential.identityToken == null) {
      throw Exception('Identity Token is null');
    }

    // Crear credencial OAuth para Firebase
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken!,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );
    
    // Iniciar sesión con Firebase usando la credencial
    final UserCredential userCredential = 
        await _auth.signInWithCredential(oauthCredential);
    final User? user = userCredential.user;
    
    if (user != null) {
      // Extraer nombre del usuario 
      String? name = user.displayName ?? 
                     (appleCredential.givenName != null && appleCredential.familyName != null 
                      ? '${appleCredential.givenName} ${appleCredential.familyName}' 
                      : user.email?.split('@')[0] ?? 'Usuario Apple');
      
      final client = Client(
        email: user.email ?? '',
        name: name,
        birthdate: '00/00/0000',
      );
      
      // Attempt to login with your custom use case
      try {
        await loginGoogleUsecase.execute(client);

      final updateGetx = Get.find<UpdateGetx>();
      updateGetx.isPasswordAuthProvider.value = false;
            String? tokenDevice = await messaging.getToken();
    print('Device Token: $tokenDevice');
    idDeviceUsecase.execute(tokenDevice);
      state.value = LoginclientSuccessfully();
      Get.offAll(() => HomePage(selectedIndex: 1));
      } catch (e) {
        print('Error in custom login use case: $e');
        // You might want to handle this differently based on your app's requirements
      }
      
    }
  } on FirebaseAuthException catch (e) {
    print('Firebase Auth Error Details:');
    print('Error Code: ${e.code}');
    print('Error Message: ${e.message}');
    print('Error: $e');

    String errorMessage = 'Error de autenticación con Apple.';
    
    if (e.code == 'invalid-credential') {
      errorMessage += ' Las credenciales no son válidas. Asegúrate de que la configuración de Apple Sign-In sea correcta.';
    }

    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error de Autenticación',
      text: errorMessage,
      confirmBtnText: 'OK',
    );
  } catch (e) {
    print('Unexpected Apple Sign-In Error: $e');
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error',
      text: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      confirmBtnText: 'OK',
    );
  } finally {
    isLoading.value = false;
  }
}
// Improved nonce generation methods
String _generateNonce([int length = 32]) {
  final random = Random.secure();
  return List.generate(length, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
}