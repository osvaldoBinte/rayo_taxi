import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:rayo_taxi/features/client/presentation/pages/add_client/addclient/client_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/add_client/get_genders_controller/get_genders_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/login/login_clients_page.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';

class RegisterClientsPage extends StatefulWidget {
  @override
  _RegisterClientsPageState createState() => _RegisterClientsPageState();
}

class _RegisterClientsPageState extends State<RegisterClientsPage> {
  final _formKey = GlobalKey<FormState>();

  final ClientGetx _clientGetx = Get.find<ClientGetx>();
  final GetGendersGetx _gendersGetx = Get.find<GetGendersGetx>();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _gendersGetx.fetchCoDetailsGetGenders(FetchgetDetailsEvent());
    
    // Suscribirse a cambios en el estado para mostrar alertas
    ever(_clientGetx.state, (state) {
      if (state is ClientCreatedSuccessfully) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Registro exitoso',
          text: 'Ahora puede iniciar sesión',
          onConfirmBtnTap: () {
            Get.offAll(() => LoginClientsPage());
          },
        );
        _clientGetx.state.value = ClientInitial();
      } else if (state is ClientCreationFailure) {
        final errorMsg = state.error;
        if (errorMsg.contains("El email ya existe")) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Error en el registro',
            text: 'El correo electrónico ya está registrado. Por favor utilice otro o inicie sesión.',
          );
        } else {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Error en el registro',
            text: errorMsg,
          );
        }
        _clientGetx.state.value = ClientInitial();
      }
    });
  }

  @override
  void dispose() {
    // Limpiar suscriptores para evitar memory leaks
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Theme.of(context).colorScheme.loader.withOpacity(0.5),
      child: Center(
        child: SpinKitFadingCube(
          color: Theme.of(context).colorScheme.loader,
          size: 50.0,
        ),
      ),
    );
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
                double availableHeight = constraints.maxHeight * 0.15;
                return Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Image.asset(
                      'assets/images/logo-new.png',
                      width: screenWidth * 0.8,
                      height: availableHeight,
                      fit: BoxFit.contain,
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
                height: screenHeight * 0.65,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        _buildTextFormField(
                          controller: _clientGetx.nameController,
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
                          controller: _clientGetx.birthdateController,
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
                              String formattedDate =
                                  DateFormat('dd/MM/yyyy', 'es_ES')
                                      .format(pickedDate);

                              setState(() {
                                _clientGetx.birthdateController.text =
                                    formattedDate;
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
                          controller: _clientGetx.emailController,
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
                        Obx(() {
                          if (_gendersGetx.state.value is GetGendersLoading) {
                            return CircularProgressIndicator();
                          } else if (_gendersGetx.state.value is GetGendersLoaded) {
                            var genders = (_gendersGetx.state.value as GetGendersLoaded).genders;

                            return DropdownButtonFormField<int>(
                              value: _clientGetx.selectedGenderId.value,
                              decoration: InputDecoration(
                                labelText: 'Género',
                                labelStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
                                prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: genders.map((gender) {
                                return DropdownMenuItem<int>(
                                  value: gender.id,
                                  child: Text(gender.label),
                                );
                              }).toList(),
                              onChanged: (value) {
                                _clientGetx.selectedGenderId.value = value;
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor seleccione su género';
                                }
                                return null;
                              },
                            );
                          } else if (_gendersGetx.state.value is GetGendersFailure) {
                            return Text('Error al cargar géneros');
                          } else {
                            return SizedBox.shrink();
                          }
                        }),
                        SizedBox(height: 20),
                        Obx(() {
                          return _buildPasswordFormField(
                            controller: _clientGetx.passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock,
                            obscureText: !_clientGetx.isPasswordVisible.value,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _clientGetx.isPasswordVisible.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: _clientGetx.togglePasswordVisibility,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su contraseña';
                              }
                              return null;
                            },
                          );
                        }),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _clientGetx.registerClient();
                            }
                          },
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Overlay para estado de carga
          Obx(() {
            if (_clientGetx.state.value is ClientLoading) {
              return _buildLoadingOverlay();
            }
            return SizedBox.shrink();
          }),
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
    Widget? suffixIcon,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
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

  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
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
    );
  }
}