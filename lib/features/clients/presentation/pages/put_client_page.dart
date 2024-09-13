import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/client.dart';
import '../getxs/update/Update_getx.dart';

class EditProfilePage extends StatefulWidget {
  final Client client;

  const EditProfilePage({required this.client});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UpdateGetx _updateGetx = Get.find<UpdateGetx>();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _oldController;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _oldController = TextEditingController(text: widget.client.years_old?.toString());
  }

  void _update() {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      String password = _passwordController.text;
      int years_old = int.parse(_oldController.text);
      final post = Client(
        id: widget.client.id,
        name: name,
        password: password,
        years_old: years_old,
      );
      print(post);
      _updateGetx.updateGetx(CreateUpdateEvent(post));
      print(_updateGetx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                controller: _oldController,
                decoration: InputDecoration(
                  labelText: 'Edad',
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
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La edad es requerida';
                  }
                  final age = int.tryParse(value);
                  if (age == null) {
                    return 'Debe ingresar un número válido';
                  }
                  if (age < 18) {
                    return 'La edad debe ser mayor o igual a 18 años';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  labelStyle: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es requerida';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
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
    );
  }
}
