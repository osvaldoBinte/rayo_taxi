import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import '../../../domain/entities/client.dart';
import '../../getxs/get/get_client_getx.dart';
import '../../getxs/update/Update_getx.dart';

class EditProfilePage extends StatefulWidget {
  final Client client;

  const EditProfilePage({super.key, required this.client});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
final UpdateGetx _updateGetx = Get.find<UpdateGetx>();
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final FocusNode _focusNodeName = FocusNode();
  final FocusNode _focusNodeBirthdate = FocusNode();
  final FocusNode _focusNodeOldPassword = FocusNode();
  final FocusNode _focusNodeNewPassword = FocusNode();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _showPasswordFields = false;

  @override
 void initState() {
    super.initState();
    _updateGetx.initializeControllers(widget.client);
  }
 Widget _buildLoadingOverlay() {
    return Container(
     // color: Colors.black.withOpacity(0.5),
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                   CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade200,
                          child: Obx(() => _updateGetx.imagePath.value == null
                              ? ClipOval(
                                  child: Image.network(
                                    widget.client.path_photo ?? '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                )
                              : ClipOval(
                                  child: Image.file(
                                    File(_updateGetx.imagePath.value!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                )),
                        ),
                    _buildIcon(
                          Icons.edit,
                          Colors.white,
                          () async {
                            final pickedFile = await _picker.pickImage(
                                source: ImageSource.gallery);
                            if (pickedFile != null) {
                              _updateGetx.setImagePath(pickedFile.path);
                            }
                          },
                          bottom: 0,
                          right: 0,
                        ),
                  ],
                ),
                Text(
                  'Editar Perfil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  focusNode: _focusNodeName,
                  controller: _updateGetx.nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(
                        _focusNodeBirthdate); 
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  focusNode: _focusNodeBirthdate,
                  controller: _updateGetx.birthdateController,
                  decoration: InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    labelStyle: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(Icons.cake, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(
                        _focusNodeOldPassword); 
                  },
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
                              primary:
                                  Color(0xFFEFC300), 
                              onPrimary: Colors
                                  .white, 
                              onSurface: Colors
                                  .black, // Color del texto del calendario
                            ),
                            dialogBackgroundColor:
                                Colors.white, // Color de fondo del diálogo
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('dd/MM/yyyy').format(pickedDate);
                      setState(() {
                        _updateGetx.birthdateController.text = formattedDate;
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showPasswordFields = !_showPasswordFields;
                    });
                  },
                  child: Text(
                    _showPasswordFields
                        ? 'Ocultar Cambio de Contraseña'
                        : 'Cambiar Contraseña',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.buttonColormap,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showPasswordFields ? 160 : 0,
                  child: _showPasswordFields
                      ? Column(
                          children: [
                            TextFormField(
                              focusNode: _focusNodeOldPassword,
                              controller: _updateGetx.oldPasswordController,
                              obscureText: !_isOldPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Contraseña Anterior',
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon:
                                    Icon(Icons.lock, color: Colors.grey[600]),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isOldPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isOldPasswordVisible =
                                          !_isOldPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).requestFocus(
                                    _focusNodeNewPassword); // Move focus to next field
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La contraseña anterior es requerida';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              focusNode: _focusNodeNewPassword,
                              controller: _updateGetx.newPasswordController,
                              obscureText: !_isNewPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Contraseña Nueva',
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon:
                                    Icon(Icons.lock, color: Colors.grey[600]),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isNewPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isNewPasswordVisible =
                                          !_isNewPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La nueva contraseña es requerida';
                                }
                                if (value.length < 5) {
                                  return 'La contraseña debe tener al menos 5 caracteres';
                                }
                                return null;
                              },
                            ),
                          ],
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _updateGetx.updateClient();
                     // Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Guardar Cambios',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.buttonColormap,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                  // Loading overlay
          Obx(() {
            if (_updateGetx.state.value is UpdateLoading) {
              return _buildLoadingOverlay();
            }
            return const SizedBox.shrink();
          }),
              ],
              
            ),
            
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color, Function onPressed,
      {double? top, double? right, double? bottom, double? left}) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        onPressed: () async => await onPressed(),
      ),
    );
  }
}
