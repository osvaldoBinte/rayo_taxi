import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/Clients/presentation/getxs/get/get_client_getx.dart';
import 'weight.dart';

class GetClientPage extends StatefulWidget {
  @override
  _GetClientPageState createState() => _GetClientPageState();
}

class _GetClientPageState extends State<GetClientPage> {
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();
  int _pageIndex = 0; 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Mi Perfil'),
      body: Container(
        color: const Color.fromARGB(255, 255, 255, 255), 
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          final state = getClientGetx.state.value;

          if (state is GetClientLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GetClientFailure) {
            return Center(
              child: Text(
                state.error,
                style: const TextStyle(color: Colors.redAccent, fontSize: 18),
              ),
            );
          } else if (state is GetClientLoaded) {
            final client = state.client.isNotEmpty ? state.client[0] : null;

            if (client == null) {
              return const Center(
                child: Text(
                  'Cliente no encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFEFC300),
                      child: Text(
                        client.name?.substring(0, 1) ?? 'N',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          print("hola");
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.edit,
                            color: const Color(0xFFEFC300), 
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  client.name ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  client.email ?? 'Sin email',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    title: Text(
                      'Edad: ${client.years_old ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    trailing: Icon(
                      Icons.cake,
                      color: const Color(0xFFEFC300), // Cambiado a #EFC300
                      size: 30,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Editar Cliente',
                    style: TextStyle(
                      color: Colors.white, 
                    ),
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
              ],
            );
          }

          return Container(); 
        }),
      ),
     
    );
  }
}
