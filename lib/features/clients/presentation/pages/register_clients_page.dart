import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rayo_taxi/features/clients/domain/entities/client.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/client/client_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/login_clients_page.dart'; // Importa la página de login
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/main.dart';

class RegisterClientsPage extends StatefulWidget {
  @override
  _RegisterClientsPageState createState() => _RegisterClientsPageState();
}

class _RegisterClientsPageState extends State<RegisterClientsPage> {
  final _formKey = GlobalKey<FormState>();
  final ClientGetx _clientGetx = Get.find<ClientGetx>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // Nueva variable para controlar la visibilidad de la contraseña
  bool _isPasswordVisible = false;

  Future<void> _register() async {
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

      await _clientGetx.createClient(CreateClientEvent(client));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            color: Theme.of(context).colorScheme.backgroundColorLogin,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                double availableHeight = constraints.maxHeight * 0.15; // 15% del espacio disponible
                return Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Image.asset(
                      'assets/images/logo-new.png',
                      width: screenWidth * 0.8,
                      height: availableHeight, // Ajustar la altura disponible
                      fit: BoxFit.contain, // Mantener la imagen completa sin recortes
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                color: Colors.white,
                height: screenHeight * 0.65, // Fija la altura al 65% de la pantalla
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: SingleChildScrollView(
                  child: Form(
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
                        _buildTextFormField(
                          controller: _birthdateController,
                          label: 'Fecha de nacimiento',
                          icon: Icons.cake,
                          readOnly: true,
                          onTap: () async {
                            DateTime today = DateTime.now();
                            DateTime eighteenYearsAgo = DateTime(
                                today.year - 18, today.month, today.day);
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: eighteenYearsAgo,
                              firstDate: DateTime(1900),
                              lastDate: eighteenYearsAgo,
                              locale: const Locale('es', 'ES'),
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
                            if (pickedDate != null) {
                              String formattedDate = DateFormat('dd/MM/yyyy', 'es_ES').format(pickedDate);

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
                          focusNode: _emailFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passwordFocus);
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
                        SizedBox(height: 20),
                        _buildPasswordFormField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          icon: Icons.lock,
                          obscureText: !_isPasswordVisible, // Usa el estado para mostrar u ocultar la contraseña
                          focusNode: _passwordFocus,
                          onFieldSubmitted: (_) {
                            _register();
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible; // Cambia el estado para mostrar u ocultar
                              });
                            },
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
                          onPressed: _register,
                          child: Text(
                            'Registrarse',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.textButton,
                                fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.buttonColor,
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                        SizedBox(height: 20),
                        Obx(() {
                          if (_clientGetx.state.value is ClientLoading) {
                            return CircularProgressIndicator();
                          } else if (_clientGetx.state.value is ClientCreatedSuccessfully) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              QuickAlert.show(
                                context: context,
                                type: QuickAlertType.success,
                                title: 'Registro exitoso',
                                text: 'Ahora puede iniciar sesión',
                                onConfirmBtnTap: () {
                                  Get.offAll(() => LoginClientsPage());
                                },
                              );
                            });
                            _clientGetx.state.value = ClientInitial();
                            return SizedBox.shrink();
                          } else if (_clientGetx.state.value is ClientCreationFailure) {
                            final errorState = _clientGetx.state.value as ClientCreationFailure;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              QuickAlert.show(
                                context: context,
                                type: QuickAlertType.error,
                                title: 'Error en el registro',
                                text: errorState.error,
                              );
                            });
                            _clientGetx.state.value = ClientInitial();
                            return SizedBox.shrink();
                          } else {
                            return SizedBox.shrink();
                          }
                        }),
                      ],
                    ),
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
    FocusNode? focusNode,
    TextInputAction textInputAction = TextInputAction.next,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
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
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
    );
  }

  // Método para crear el campo de contraseña con un ícono para mostrar/ocultar
  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscureText = true,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
    Function(String)? onFieldSubmitted,
    Widget? suffixIcon, // Aquí agregamos el ícono para mostrar/ocultar la contraseña
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: suffixIcon, // Añade el ícono al campo de texto
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
    );
  }
}
