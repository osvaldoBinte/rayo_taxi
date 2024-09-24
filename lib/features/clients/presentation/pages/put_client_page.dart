
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/client.dart';
import '../getxs/get/get_client_getx.dart';
import '../getxs/update/Update_getx.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  final Client client;

  const EditProfilePage({super.key, required this.client});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UpdateGetx _updateGetx = Get.find<UpdateGetx>();
  final _formKey = GlobalKey<FormState>();
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();

  late final TextEditingController _nameController;
  late final TextEditingController _birthdateController;
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNodeName = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _birthdateController =
        TextEditingController(text: widget.client.birthdate?.toString());
  }

  void _update() {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      String password = _passwordController.text;
      String birthdate = _birthdateController.text;
      final post = Client(
        id: widget.client.id,
        name: name,
        password: password,
        birthdate: birthdate,
      );
      _updateGetx.updateGetx(CreateUpdateEvent(post));
      getClientGetx.fetchCoDetails(FetchgetDetailsEvent());
    }
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
                  focusNode: _focusNodeName, // Añade el FocusNode aquí
                  controller: _nameController,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthdateController,
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
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('dd/MM/yyyy').format(pickedDate);
                      setState(() {
                        _birthdateController.text = formattedDate;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La fecha de nacimiento es requerida';
                    }

                    final birthdate = DateFormat('dd/MM/yyyy').parse(value);
                    final today = DateTime.now();
                    final age = today.year - birthdate.year;

                    if (age < 18 ||
                        (age == 18 &&
                            today.isBefore(DateTime(
                                today.year, birthdate.month, birthdate.day)))) {
                      return 'Debes tener al menos 18 años';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  focusNode: _focusNodePassword, // Añade el FocusNode aquí
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    labelStyle: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es requerida';
                    }
                    if (value.length < 5) {
                      return 'La contraseña debe tener al menos 5 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _update();
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Guardar Cambios',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFC300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
