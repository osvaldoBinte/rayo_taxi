import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/client/client_getx.dart';
import 'package:intl/intl.dart';
import 'package:rayo_taxi/main.dart';

class RegisterClientsPage extends StatefulWidget {
  @override
  _RegisterClientsPage createState() => _RegisterClientsPage();
}

class _RegisterClientsPage extends State<RegisterClientsPage> {
  final _formKey = GlobalKey<FormState>();
  final ClientGetx _clientGetx = Get.find<ClientGetx>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
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
      String name = _nameController.text;
      String password = _passwordController.text;
      String email = _emailController.text;
      String birthdate = _birthdateController.text;

      final client = Client(
        name: name,
        password: password,
        email: email,
        birthdate: birthdate,
      );

      _clientGetx.createClient(CreateClientEvent(client));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Asegúrate de que resizeToAvoidBottomInset esté en true
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            color: Theme.of(context).colorScheme.backgroundColor,
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
          // Envolvemos todo en SingleChildScrollView
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.35,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Registrarse',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      Obx(() {
                        if (_clientGetx.state.value is ClientCreatedSuccessfully) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Registro exitoso',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        } else if (_clientGetx.state.value is ClientCreationFailure) {
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
                          children: <Widget>[
                            _buildTextFormField(
                              controller: _nameController,
                              label: 'Nombre',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su nombre';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            // Usamos _buildTextFormField para el campo de fecha
                            _buildTextFormField(
                              controller: _birthdateController,
                              label: 'Fecha de nacimiento',
                              icon: Icons.cake,
                              readOnly: true,
                              onTap: () async {
                                DateTime today = DateTime.now();
                                DateTime eighteenYearsAgo = DateTime(
                                  today.year - 18,
                                  today.month,
                                  today.day,
                                );

                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: eighteenYearsAgo,
                                  firstDate: DateTime(1900),
                                  lastDate: eighteenYearsAgo,
                                  builder: (BuildContext context, Widget? child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
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

                                if (pickedDate != null) {
                                  String formattedDate = DateFormat('dd/MM/yyyy')
                                      .format(pickedDate);
                                  setState(() {
                                    _birthdateController.text = formattedDate;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La fecha de nacimiento es requerida';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
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
                            _buildTextFormField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              icon: Icons.lock,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese su contraseña';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _register,
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
                            SizedBox(height: 20), // Añadimos espacio al final
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
    bool readOnly = false,
    VoidCallback? onTap,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0), // Ajustamos el padding
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        readOnly: readOnly,
        onTap: onTap,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
