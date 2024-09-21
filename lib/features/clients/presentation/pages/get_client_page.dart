import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/get/get_client_getx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/client.dart';
import 'edit_porfile_modal.dart';
import 'login_clients_page.dart';
import 'dart:async';

class GetClientPage extends StatefulWidget {
  const GetClientPage({super.key});

  @override
  State<GetClientPage> createState() => _GetClientPage();
}

class _GetClientPage extends State<GetClientPage> {
  late StreamSubscription<ConnectivityResult> subscription;
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    Get.offAll(() => LoginClientsPage());
  }

  @override
  void initState() {
    super.initState();
    getClientGetx.fetchCoDetails(FetchgetDetailsEvent());

    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se perdió la conectividad Wi-Fi'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        getClientGetx.fetchCoDetails(FetchgetDetailsEvent());
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
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
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: Icon(Icons.logout, size: 30.0, color: Colors.red),
                      onPressed: _logout,
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Color.fromARGB(255, 243, 222, 33),
                        child: Text(
                          client.name?.substring(0, 1) ?? 'N',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildIcon(
                          Icons.edit, Color.fromARGB(255, 255, 255, 255), () {},
                          bottom: 0, right: 0),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    client.name ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    client.email ?? 'Sin email',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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
                          fontSize: 20,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.cake,
                        color: Color(0xFFEFC300),
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (BuildContext context) {
                          return FractionallySizedBox(
                            heightFactor: 0.75,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: Container(
                                color: Colors.white,
                                child: EditProfileModal(client: client),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Editar Perfil',
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
      ),
    );
  }
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
