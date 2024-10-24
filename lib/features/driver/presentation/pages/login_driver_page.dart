import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rayo_taxi/connectivity_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Importar flutter_spinkit
import 'package:rayo_taxi/main.dart';

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
  bool _isLoading = false; // Nueva variable para rastrear la carga

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _login() async {
    // Verificar conectividad
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _errorMessage = 'No tienes conexión a Internet. Verifica tu red.';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Iniciar carga
        _errorMessage = '';
      });

      String password = _passwordController.text;
      String email = _emailController.text;
      final driver = Driver(email: email, password: password);

      try {
        await _driverGetx.createClient(LoginDriverEvent(driver));

        if (_driverGetx.state.value is LogindriverSuccessfully) {
          // Redirigir al HomePage
          Get.offAll(() => HomePage());
        } else if (_driverGetx.state.value is LogindriverFailure) {
          final failureState = _driverGetx.state.value as LogindriverFailure;
          setState(() {
            _errorMessage = failureState.error;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Ocurrió un error inesperado. Inténtalo nuevamente.';
        });
        print('Error durante el inicio de sesión: $e');
      } finally {
        setState(() {
          _isLoading = false; // Finalizar carga
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.backgroundColorLogin,
        resizeToAvoidBottomInset: true,
        body: Stack(children: [
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
                      height: screenHeight * 0.29,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Contenedor blanco fijo que ocupa el espacio restante con borde superior redondeado
              Expanded(
                child: Container(
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
                      crossAxisAlignment: CrossAxisAlignment
                          .stretch, // Para que los botones ocupen todo el ancho
                      children: <Widget>[
                        Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center, // Centra el texto
                        ),
                        SizedBox(height: 20),
                        Obx(() {
                          if (_driverGetx.state.value
                              is LogindriverSuccessfully) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Inicio de sesión exitoso',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          } else if (_driverGetx.state.value
                              is LogindriverFailure) {
                            final failureState =
                                _driverGetx.state.value as LogindriverFailure;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Correo electrónico',
                                    labelStyle:
                                        TextStyle(color: Color(0xFF545454)),
                                    filled: true,
                                    fillColor: Color(0xFFD9D9D9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: TextStyle(color: Colors.black),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context)
                                        .nextFocus(); // Enfocar campo de contraseña
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    labelStyle:
                                        TextStyle(color: Color(0xFF545454)),
                                    filled: true,
                                    fillColor: Color(0xFFD9D9D9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
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
                                  style: TextStyle(color: Colors.black),
                                  obscureText: _obscureText,
                                  textInputAction: TextInputAction.done,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _login, // Deshabilitar botón si está cargando
                                  child: _isLoading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SpinKitFadingCube(
                                              // Usando SpinKitFadingCube
                                              color: Colors.white,
                                              size: 24.0,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Cargando...',
                                              style: TextStyle(
                                                color: Colors.white,
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
                                    backgroundColor:Theme.of(context).colorScheme.buttonColor,
                                    minimumSize: Size(double.infinity,
                                        50), // Botón de ancho completo
                                  ),
                                ),
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

          // Indicador de Carga Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: SpinKitFadingCube(
                  // Usando SpinKitFadingCube
                  color: Theme.of(context).colorScheme.buttonColor,
                  size: 50.0,
                ),
              ),
            ),
        ]));
  }
}
