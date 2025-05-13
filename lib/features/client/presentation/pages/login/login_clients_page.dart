import 'dart:convert';

import 'package:crypto/crypto.dart';
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
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../domain/entities/client.dart';
import 'loginclient_getx.dart';
import '../add_client/register_clients_page.dart';
import 'package:quickalert/quickalert.dart';
import 'dart:io' show Platform;

class LoginClientsPage extends StatefulWidget {
  @override
  _LoginClientsPage createState() => _LoginClientsPage();
}

class _LoginClientsPage extends State<LoginClientsPage> {
  final LoginclientGetx _clientGetx = Get.find<LoginclientGetx>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isGoogleLoading = false;
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

void _loginWithApple() {
  _clientGetx.loginWithApple();
}

  void _loginWithGoogle() {
    _clientGetx.loginWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFF303030),
      statusBarIconBrightness: Brightness.light,
    ));

    final screenHeight = MediaQuery.of(context).size.height;
  List<Widget> buttons = [];

    return WillPopScope(
        onWillPop: () => _clientGetx.handleBackButton(),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.backgroundColorLogin,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              Column(
                children: <Widget>[
              SafeArea(
      child: Container(
        padding: EdgeInsets.only(top: screenHeight * 0.05),
        margin: EdgeInsets.only(bottom: screenHeight * 0.05), // Añadimos margen inferior
        child: Align(
          alignment: Alignment.topCenter,
          child: Image.asset(
            'assets/images/logo-new.png',
            width: MediaQuery.of(context).size.width * 0.6,
            height: screenHeight * 0.20,
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
                                          icon: Icon(Icons.edit,
                                              color: Colors.grey),
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
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .loader,
                                                    size: 24.0,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    'Cargando...',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .textButton,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                          minimumSize:
                                              Size(double.infinity, 50),
                                        ),
                                      );
                                    }),
                                    SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Get.offAll(
                                              () => CreateRecoveryCode());
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
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .buttonColor,
                                      minimumSize: Size(double.infinity,
                                          50), // Botón de ancho completo
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                 Obx(() {
    // Only add Google button if available
    if (_clientGetx.isGoogleSignInAvailable.value) {
      buttons.add(
        _buildSocialLoginButton(
          imagePath: 'assets/images/google.png',
          text: 'Iniciar sesión con Google',
          onPressed: _loginWithGoogle,
        )
      );
      buttons.add(SizedBox(height: 20));
    }
    return Column(children: buttons);
  }),
                                  SizedBox(height: 20),
                                if (Platform.isIOS)
      _buildSocialLoginButton(
        icon: Icons.apple,
        text: 'Iniciar sesión con Apple',
        color: Colors.black,
        onPressed: _loginWithApple,
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
                  color: Theme.of(context).colorScheme.loader.withOpacity(0.5),
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
        ));
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
