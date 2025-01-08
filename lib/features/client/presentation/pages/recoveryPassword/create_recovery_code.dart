import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'create_recovery_code_controller.dart';

class CreateRecoveryCode extends StatelessWidget {
  // Instancia del controlador
  final CreateRecoveryCodeController controller = Get.find<CreateRecoveryCodeController>();

  @override
  Widget build(BuildContext context) {
    // Configuración de la barra de estado
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
                  margin: EdgeInsets.only(bottom: 25.0),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Recuperar contraseña',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Obx(() {
                          switch (controller.currentStep.value) {
                            case RecoveryStep.Email:
                              return _buildEmailStep(context);
                            case RecoveryStep.Code:
                              return _buildCodeStep(context);
                            case RecoveryStep.UpdatePassword:
                              return _buildUpdatePasswordStep(context);
                            default:
                              return SizedBox.shrink();
                          }
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Indicador de carga (opcional)
          Obx(() {
            if (controller.isLoading.value) {
              return Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(),
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

  // Widget para el Paso 1: Ingresar Email
  Widget _buildEmailStep(BuildContext context) {
    return Form(
      child: Column(
        children: <Widget>[
          _buildTextFormField(
            controller: controller.emailController,
            label: 'Confirmar tu Correo electrónico',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese su correo electrónico';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Por favor ingrese un correo electrónico válido';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: controller.sendRecoveryCode,
            child: Text(
              'Enviar Código de Recuperación',
              style: TextStyle(
                color: Theme.of(context).colorScheme.textButton,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.buttonColor,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget para el Paso 2: Ingresar Código de Recuperación
  Widget _buildCodeStep(BuildContext context) {
    return Form(
      child: Column(
        children: <Widget>[
          Text(
            'Ingresa el código de recuperación enviado a tu correo',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          PinCodeTextField(
            appContext: context,
            length: 6,
            controller: controller.codeController,
            keyboardType: TextInputType.number,
            autoDismissKeyboard: true,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(5),
              fieldHeight: 50,
              fieldWidth: 40,
              activeFillColor: Colors.white,
              inactiveFillColor: Colors.white,
              selectedFillColor: Colors.white,
              activeColor: Colors.blue,
              selectedColor: Colors.blue,
              inactiveColor: Colors.grey,
            ),
            animationDuration: Duration(milliseconds: 300),
            enableActiveFill: true,
           
              beforeTextPaste: (text) {
            return true;
            
          },
          
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: controller.validateRecoveryCode,
            child: Text(
              'Validar',
              style: TextStyle(
                color: Theme.of(context).colorScheme.textButton,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.buttonColor,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
          SizedBox(height: 20),
           Obx(() {
          int minutes = controller.remainingSeconds.value ~/ 60;
          int seconds = controller.remainingSeconds.value % 60;
          String timerText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          return Text(
            'Tiempo restante: $timerText',
            style: TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          );
        }),
        ],
      ),
    );
  }

  // Widget para el Paso 3: Actualizar Contraseña
  Widget _buildUpdatePasswordStep(BuildContext context) {
    return Form(
      child: Column(
        children: <Widget>[
          // Campo de Nueva Contraseña con icono de ojo
          Obx(() {
            return _buildTextFormField(
              controller: controller.newPasswordController,
              label: 'Nueva Contraseña',
              icon: Icons.lock,
              obscureText: !controller.isNewPasswordVisible.value,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isNewPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: controller.toggleNewPasswordVisibility,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese una nueva contraseña';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            );
          }),
          SizedBox(height: 20),
          // Campo de Confirmar Contraseña con icono de ojo
          Obx(() {
            return _buildTextFormField(
              controller: controller.confirmPasswordController,
              label: 'Confirmar Contraseña',
              icon: Icons.lock_outline,
              obscureText: !controller.isConfirmPasswordVisible.value,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isConfirmPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: controller.toggleConfirmPasswordVisibility,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor confirme su contraseña';
                }
                if (value != controller.newPasswordController.text.trim()) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            );
          }),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: controller.updatePassword,
            child: Text(
              'Actualizar Contraseña',
              style: TextStyle(
                color: Theme.of(context).colorScheme.textButton,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.buttonColor,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Método para construir los campos de texto
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
}
