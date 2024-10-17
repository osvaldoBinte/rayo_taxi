import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/login/loginclient_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/edit_porfile_modal.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/login_clients_page.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/pagos/animated_modal_bottom.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/pagos/pago_page.dart';
import 'package:rayo_taxi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/getxs/get/get_client_getx.dart';
import 'presentation/getxs/calculateAge/calculateAge_getx.dart';

class GetClientPage extends StatefulWidget {
  const GetClientPage({super.key});

  @override
  State<GetClientPage> createState() => _GetClientPageState();
}

class _GetClientPageState extends State<GetClientPage> {
  late StreamSubscription<ConnectivityResult> subscription;
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();
  final CalculateAgeGetx calculateAgeGetx = Get.find<CalculateAgeGetx>();
  final LoginclientGetx _loginGetx = Get.find<LoginclientGetx>();

  final _picker = ImagePicker();
  String? _imagePath;

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _loginGetx.logout();

    await prefs.remove('auth_token');
    await Get.offAll(() => LoginClientsPage());
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final state = getClientGetx.state.value;

          if (state is GetClientLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GetClientFailure) {
            return Center(
              child: Text(
                state.error,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 18),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _imagePath != null
                              ? FileImage(File(_imagePath!))
                              : null,
                          child: _imagePath == null
                              ? ClipOval(
                                  child: Image.network(
                                    client.path_photo ?? '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Obx(() {
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
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.icongreen,
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
                          Text(
                            '${client.email ?? 'Sin email'}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.icongreen,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCardButton(
                      context,
                      icon: Icons.logout,
                      label: 'Cerrar Sesión',
                      onPressed: _logout,
                    ),
                    _buildCardButton(
                      context,
                      icon: Icons.payment,
                      label: 'Pago',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return AnimatedModalBottomSheet();
                          },
                        );
                      },
                    ),
                    _buildCardButton(
                      context,
                      icon: Icons.info_outline,
                      label: 'Información',
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
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildListOption(
                  icon: Icons.payment,
                  title: 'Mis Tarjetas',
                  subtitle: 'Metodos de pagos agregador',
                ),
                _buildListOption(
                  icon: Icons.card_membership,
                  title: 'Taxi',
                  subtitle: 'información adicional ',
                ),
                _buildListOption(
                  icon: Icons.security,
                  title: 'Control de seguridad',
                  subtitle: 'Conoce cómo hacer que los viajes sean más seguros',
                ),
                _buildListOption(
                  icon: Icons.privacy_tip,
                  title: 'Revisión de privacidad',
                  subtitle: 'Haz un recorrido interactivo por tu configuración',
                ),
                const SizedBox(height: 30),

                // Botón de Cerrar Sesión
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _logout, // Acción para cerrar sesión
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            );
          }
          return Container();
        }),
      ),
    );
  }

  Widget _buildCardButton(BuildContext context,
      {required IconData icon,
      required String label,
      VoidCallback? onPressed}) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed ?? () {},
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: Colors.black),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildListOption(
      {required IconData icon,
      required String title,
      required String subtitle,
      Widget? trailing}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: trailing,
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
