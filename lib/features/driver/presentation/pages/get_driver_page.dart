import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/presentation/getxs/login/logindriver_getx.dart';
import 'package:rayo_taxi/features/driver/presentation/pages/login_driver_page.dart';
import 'package:rayo_taxi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

import '../getxs/get/get_driver_getx.dart';

class GetDriverPage extends StatefulWidget {
  const GetDriverPage({super.key});

  @override
  State<GetDriverPage> createState() => _GetDriverPage();
}

class _GetDriverPage extends State<GetDriverPage> {
  late StreamSubscription<ConnectivityResult> subscription;
  final GetDriverGetx getDriveGetx = Get.find<GetDriverGetx>();
  final LogindriverGetx _driverGetx = Get.find<LogindriverGetx>();

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _driverGetx.logout();
    await prefs.remove('auth_token');
    await Get.offAll(() => LoginDriverPage());
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getDriveGetx.fetchCoDetails(FetchgetDetailsEvent());
    });

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
        getDriveGetx.fetchCoDetails(FetchgetDetailsEvent());
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
          final state = getDriveGetx.state.value;

          if (state is GetDriverLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GetDriverFailure) {
            return Center(
              child: Text(
                state.error,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 18),
              ),
            );
          } else if (state is GetDriverLoaded) {
            final drive = state.drive.isNotEmpty ? state.drive[0] : null;

            if (drive == null) {
              return const Center(
                child: Text(
                  'Conductor no encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              );
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
                          child: ClipOval(
                            child: Image.network(
                              drive.path_photo ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (BuildContext context,
                                  Object exception, StackTrace? stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drive.name ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text('Edad: ${drive.years_old ?? 'N/A'}',
                              style: Theme.of(context).textTheme.bodyLarge),
                          Text(drive.email ?? 'Sin email',
                              style: Theme.of(context).textTheme.bodyLarge),
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
                  ],
                ),
                const SizedBox(height: 30),
                _buildListOption(
                  icon: Icons.directions_car,
                  title: 'Vehículo',
                  subtitle: 'Información adicional',
                ),
                _buildListOption(
                  icon: Icons.help_outline,
                  title: 'Ayuda',
                  subtitle:
                      '¿Te gustaría que te ayude con algo más relacionado con tu aplicación?',
                ),
                _buildListOption(
                  icon: Icons.security,
                  title: 'Control de seguridad',
                  subtitle: 'Conoce cómo hacer que los viajes sean más seguros',
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
}
