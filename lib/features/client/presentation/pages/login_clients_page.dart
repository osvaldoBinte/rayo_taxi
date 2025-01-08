import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/loginGoogle/loginGoogle_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rayo_taxi/features/client/presentation/pages/recoveryPassword/create_recovery_code.dart';
import '../../domain/entities/client.dart';
import '../getxs/login/loginclient_getx.dart';
import 'add_client/register_clients_page.dart';
import 'package:quickalert/quickalert.dart';

class LoginClientsPage extends StatefulWidget {
  @override
  _LoginClientsPage createState() => _LoginClientsPage();
}

class _LoginClientsPage extends State<LoginClientsPage> {
  final LoginclientGetx _clientGetx = Get.find<LoginclientGetx>();
  final FirebaseAuth _auth =
      FirebaseAuth.instance; 
  bool _isGoogleLoading =
      false;
  final TextEditingController _birthdateController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isEmailEntered = false;
  bool _obscureText = true;
  final loginController = Get.find<LogingoogleGetx>();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isEmailEntered = true;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    await _clientGetx.login(email, password);
  }

  // Inicializa GoogleSignIn con los scopes necesarios
  Future<void> _showBirthdateModal() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // El usuario no puede cerrar el modal tocando fuera de él
      builder: (BuildContext context) {
        DateTime? selectedDate;

        return AlertDialog(
          title: Text('Fecha de Nacimiento'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Por favor, ingresa tu fecha de nacimiento:'),
                SizedBox(height: 20),
                TextFormField(
                  controller: _birthdateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Seleccionar fecha',
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
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
                      selectedDate = picked;
                      String formattedDate =
                          DateFormat('dd/MM/yyyy').format(picked);
                      setState(() {
                        _birthdateController.text = formattedDate;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.backgroundColorLogin,
              ),
              child: Text(
                'Continuar',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.textButton,
                ),
              ),
              onPressed: () {
                if (_birthdateController.text.isEmpty) {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text: 'Por favor, selecciona una fecha',
                    confirmBtnText: 'OK',
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
            )
          ],
        );
      },
    );
  }

  void _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });
    print('${DateTime.now()}: Iniciando Google Sign-In');

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      setState(() {
        _isGoogleLoading = false;
      });
      return;
    }
    print('${DateTime.now()}: Google Sign-In exitoso');

    GoogleSignInAuthentication? googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } catch (e) {
      print('Error al obtener la autenticación de Google: $e');
      setState(() {
        _isGoogleLoading = false;
      });
      return;
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      print('${DateTime.now()}: Iniciando Firebase Sign-In');
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      print('${DateTime.now()}: Firebase Sign-In exitoso');

      final User? user = userCredential.user;

      if (user != null) {
        // Mostrar el modal para ingresar la fecha de nacimiento
        await _showBirthdateModal();

        final client = Client(
          email: user.email ?? '',
          name: user.displayName ?? '',
          birthdate: _birthdateController.text, // Utiliza la fecha ingresada
        );

        final loginEvent = LoginGoogleEvent(client: client);
        print('${DateTime.now()}: Iniciando loginController.logingoogle()');
        await loginController.logingoogle(loginEvent);
        print('${DateTime.now()}: loginController.logingoogle() completado');

        if (loginController.state.value is LogingoogleSuccessfully) {
          print('${DateTime.now()}: Navegando a HomePage');
          Get.off(() => HomePage(selectedIndex: 1));
        } else {
          print('loginController ${loginController.state.value}');
          print(
              "${DateTime.now()}: Error: loginController.state no es LogingoogleSuccessfully");
        }
      } else {
        print(
            "${DateTime.now()}: Error: Usuario es nulo después de iniciar sesión con Google");
      }
    } catch (e) {
      print('${DateTime.now()}: Error al iniciar sesión con Google: $e');
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFF303030),
      statusBarIconBrightness: Brightness.light,
    ));

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColorLogin,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              // Contenedor de fondo con el logo
              Container(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Image.asset(
                      'assets/images/logo-new.png',
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: screenHeight * 0.25,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: 25.0), //
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center, // Centra el texto
                        ),
                        SizedBox(height: 20),
                        SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              if (!_isEmailEntered) ...[
                                _buildTextFormField(
                                  controller: _emailController,
                                  label: 'Correo electrónico',
                                  icon: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese su correo electrónico';
                                    }
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                        .hasMatch(value)) {
                                      return 'Por favor ingrese un correo electrónico válido';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _nextStep,
                                  child: Text(
                                    'Siguiente',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .textButton,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .buttonColor, // Color del botón
                                    minimumSize: Size(double.infinity,
                                        50), // Botón de ancho completo
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Correo electrónico: ${_emailController.text}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.grey),
                                      onPressed: () {
                                        setState(() {
                                          _isEmailEntered = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                _buildTextFormField(
                                  controller: _passwordController,
                                  label: 'Contraseña',
                                  icon: Icons.lock,
                                  obscureText: _obscureText,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: _togglePasswordVisibility,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese su contraseña';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 20),
                                Obx(() {
                                  return ElevatedButton(
                                    onPressed: _clientGetx.isLoading.value
                                        ? null
                                        : _login,
                                    child: _clientGetx.isLoading.value
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SpinKitFadingCube(
                                                color: Theme.of(context).colorScheme.loader,
                                                size: 24.0,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Cargando...',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .textButton,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            'Iniciar Sesión',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .textButton,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .buttonColor,
                                      minimumSize: Size(double.infinity, 50),
                                    ),
                                  );
                                }),
                                SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Get.offAll(() => CreateRecoveryCode());
                                    },
                                    child: Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                          .colorScheme
                                          .buttonColor, 
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(height: 20),

                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black,
                                      height: 36,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text("o"),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black,
                                      height: 36,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            RegisterClientsPage()),
                                  );
                                },
                                child: Text(
                                  'Registrarse',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .textButton,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.buttonColor,
                                  minimumSize: Size(double.infinity,
                                      50), // Botón de ancho completo
                                ),
                              ),
                              SizedBox(height: 20),
                              _buildSocialLoginButton(
                                imagePath: 'assets/images/google.png',
                                text: 'Iniciar sesión con Google',
                                onPressed: _loginWithGoogle,
                              ),
                              SizedBox(height: 20),
                              _buildSocialLoginButton(
                                icon: Icons.apple,
                                text: 'Iniciar sesión con Apple',
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isGoogleLoading)
            Container(
              color:Theme.of(context).colorScheme.loader.withOpacity(0.5),
              child: Center(
                child: SpinKitFadingCube(
                  color: Theme.of(context).colorScheme.loader,
                  size: 50.0,
                ),
              ),
            ),
          Obx(() {
            if (_clientGetx.isLoading.value) {
              return Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: SpinKitFadingCube(
                    color: Theme.of(context).colorScheme.loader,
                    size: 50.0,
                  ),
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildSocialLoginButton({
    String? imagePath,
    IconData? icon,
    required String text,
    Color? color,
    VoidCallback? onPressed, // Añade este parámetro
  }) {
    return GestureDetector(
      onTap:
          onPressed ?? () {}, // Llama a la función cuando se presiona el botón
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath,
                width: 24,
                height: 24,
              ),
            if (icon != null)
              Icon(
                icon,
                color: color ?? Colors.black,
              ),
            SizedBox(width: 10),
            Text(text),
          ],
        ),
      ),
    );
  }
}
