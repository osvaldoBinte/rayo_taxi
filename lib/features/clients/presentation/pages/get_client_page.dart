import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/client.dart';
import '../../domain/usecases/calculate_age_usecase.dart';
import '../getxs/calculateAge/calculateAge_getx.dart';
import 'edit_porfile_modal.dart';
import 'login_clients_page.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class GetClientPage extends StatefulWidget {
  const GetClientPage({super.key});

  @override
  State<GetClientPage> createState() => _GetClientPage();
}

class _GetClientPage extends State<GetClientPage> {
  late StreamSubscription<ConnectivityResult> subscription;

  final CalculateAgeGetx calculateAgeGetx = Get.find<CalculateAgeGetx>();
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
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor
            ],
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
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.iconred,
                      fontSize: 18),
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

              if (client.birthdate != null) {
                calculateAgeGetx.calculateAge(client.birthdate!);
              }

              return Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: Icon(Icons.logout,
                          size: 30.0,
                          color: Theme.of(context).colorScheme.iconred),
                      onPressed: _logout,
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor:
                            Theme.of(context).colorScheme.buttonColor,
                        child: Text(
                          client.name?.substring(0, 1) ?? 'N',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ),
                      _buildIcon(
                          Icons.edit,Theme.of(context).colorScheme.iconwhite, () {},
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
                        'Fecha de nacimiento: ${client.birthdate ?? 'No especificada'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      subtitle: Obx(() {
                        final ageState = calculateAgeGetx.state.value;
                        if (ageState is CalculateAgeLoading) {
                          return const Text(
                            'Calculando edad...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          );
                        } else if (ageState is CalculateAgeSuccessfully) {
                          return Text(
                            'Edad: ${ageState.age} años',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          );
                        } else if (ageState is CalculateAgeFailure) {
                          return Text(
                            'Error: ${ageState.error}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.iconred,
                              fontSize: 16,
                            ),
                          );
                        } else {
                          return const Text(
                            'Edad no disponible',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          );
                        }
                      }),
                      trailing: Icon(
                        Icons.cake,
                        color: Theme.of(context).colorScheme.buttonColor,
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
                      backgroundColor:
                          Theme.of(context).colorScheme.buttonColor,
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
