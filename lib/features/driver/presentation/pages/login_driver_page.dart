import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rayo_taxi/connectivity_service.dart';

import '../../domain/entities/driver.dart';
import '../getxs/login/logindriver_getx.dart';
import 'home_page.dart';

class LoginDriverPage extends StatefulWidget {
  @override
  _LoginDriverPage createState() => _LoginDriverPage();
}

class _LoginDriverPage extends State<LoginDriverPage> {
  final LogindriverGetx _driverGetx = Get.find<LogindriverGetx>();
  final ConnectivityService _connectivityService = ConnectivityService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  String _errorMessage = '';

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _login() async {
    if (!_connectivityService.isConnected) {
      setState(() {
        _errorMessage = 'No tienes conexión a Internet. Verifica tu red.';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = '';
      });

      String password = _passwordController.text;
      String email = _emailController.text;
      final post = Driver(email: email, password: password);

      _driverGetx.createClient(LoginDriverEvent(post));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            Container(
              color: Color.fromARGB(255, 255, 255, 255),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Image.asset(
                        'assets/images/rayo_taxi.png',
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: screenHeight * 0.29,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Text(
                    'LOGIN',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Obx(() {
                    if (_driverGetx.state.value is LogindriverSuccessfully) {
                      Future.microtask(() => Get.to(() => HomePage()));
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Exitoso',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else if (_driverGetx.state.value is LogindriverFailure) {
                      final failureState =
                          _driverGetx.state.value as LogindriverFailure;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          failureState.error,
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }),
                  SizedBox(height: 20),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              labelStyle: TextStyle(color: Color(0xFF545454)),
                              filled: true,
                              fillColor: Color(0xFFD9D9D9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next, // Next en teclado
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).nextFocus(); // Enfocar campo de contraseña
                            },
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
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              labelStyle: TextStyle(color: Color(0xFF545454)),
                              filled: true,
                              fillColor: Color(0xFFD9D9D9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Color(0xFF545454),
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                            ),
                            obscureText: _obscureText,
                            textInputAction: TextInputAction.done, // Send en teclado
                            onFieldSubmitted: (_) {
                              _login(); // Ejecutar login al presionar "Send"
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su contraseña';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton(
                            onPressed: _login,
                            child: Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFEFC300),
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
