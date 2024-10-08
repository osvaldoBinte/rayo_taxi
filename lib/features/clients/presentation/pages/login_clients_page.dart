import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/home_page.dart';
import 'package:rayo_taxi/main.dart';
import 'package:flutter/services.dart';  
import '../../domain/entities/client.dart';
import '../getxs/login/loginclient_getx.dart';
import 'register_clients_page.dart';

class LoginClientsPage extends StatefulWidget {
  @override
  _LoginClientsPage createState() => _LoginClientsPage();
}

class _LoginClientsPage extends State<LoginClientsPage> {
  final LoginclientGetx _clientGetx = Get.find<LoginclientGetx>();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isEmailEntered = false;
  bool _obscureText = true;

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

  void _login() {
    if (_formKey.currentState!.validate()) {
      String password = _passwordController.text;
      String email = _emailController.text;
      final client = Client(email: email, password: password);

      _clientGetx.createClient(LoginClientEvent(client));
    }
  }
  @override
  Widget build(BuildContext context) {
    // Ajustar el estilo de la barra de estado aquí
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFF303030),  // Color gris oscuro para la barra de estado
      statusBarIconBrightness: Brightness.light,  // Iconos de la barra en blanco para mejor contraste
    ));

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: <Widget>[
          Container(
            color: Theme.of(context).colorScheme.backgroundColorLogin,
            child: Align(
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
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.35,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                       Text(
                        'INICIAR SESIÓN',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Obx(() {
                        if (_clientGetx.state.value
                            is LoginclientSuccessfully) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage()),
                            );
                          });
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
                        } else if (_clientGetx.state.value
                            is LoginclientFailure) {
                          final failureState =
                              _clientGetx.state.value as LoginclientFailure;
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
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFEFC300),
                                  minimumSize: Size(double.infinity, 50),
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
                                    icon: Icon(Icons.edit, color: Colors.grey),
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
                              ElevatedButton(
                                onPressed: _login,
                                child: Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.buttonColor,
                                  minimumSize: Size(double.infinity, 50),
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
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.buttonColor,
                                minimumSize: Size(double.infinity, 50),
                              ),
                            ),
                            SizedBox(height: 20),
                            _buildSocialLoginButton(
                              imagePath: 'assets/images/google.png',
                              text: 'Iniciar sesión con Google',
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
          ),
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
  }) {
    return Container(
      width: 300,
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
    );
  }
}
