import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/client/client_getx.dart';

class RegisterClientsPage extends StatefulWidget {
  @override
  _RegisterClientsPage createState() => _RegisterClientsPage();
}

class _RegisterClientsPage extends State<RegisterClientsPage> {
  final _formKey = GlobalKey<FormState>();
  final ClientGetx _clientGetx = Get.find<ClientGetx>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isEmailEntered = false;

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isEmailEntered = true;
      });
    }
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      print('Email: ${_emailController.text}');
      print('Password: ${_passwordController.text}');

      String name = _nameController.text;
      String password = _passwordController.text;
      String email = _emailController.text;
      int years_old = int.parse(_oldController.text);
      print('Nombre: $name');
      print('Contraseña: $password');
      print('Correo electrónico: $email');
      final post = Client(
          name: name, password: password, email: email, years_old: years_old);
      _clientGetx.createClient(CreateClientEvent(post));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEFC300),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            color: Color(0xFFEFC300),
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Registrarse',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Obx(() {
                      if (_clientGetx.state.value
                          is ClientCreatedSuccessfully) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Registro exitoso',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      } else if (_clientGetx.state.value
                          is ClientCreationFailure) {
                        final failureState =
                            _clientGetx.state.value as ClientCreationFailure;
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
                    Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nombre',
                                labelStyle: TextStyle(color: Color(0xFF545454)),
                                filled: true,
                                fillColor: Color(0xFFD9D9D9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su nombre';
                                }

                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextFormField(
                              controller: _oldController,
                              decoration: InputDecoration(
                                labelText: 'Edad',
                                labelStyle: TextStyle(color: Color(0xFF545454)),
                                filled: true,
                                fillColor: Color(0xFFD9D9D9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su Edad';
                                }
                                final edad = int.tryParse(value);
                                if (edad == null) {
                                  return 'Por favor ingrese un número válido';
                                }

                                if (edad < 18) {
                                  return 'Debe tener al menos 18 años';
                                }

                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                              ),
                              obscureText: true,
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ElevatedButton(
                              onPressed: _register,
                              child: Text(
                                'Registrarse',
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
            ),
          ),
        ],
      ),
    );
  }
}
