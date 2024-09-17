import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  @override
  void initState() {
    super.initState();

    getDriveGetx.fetchCoDetails(FetchgetDetailsEvent());

    subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
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
        child: Container(
          color: const Color.fromARGB(255, 255, 255, 255),
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            final state = getDriveGetx.state.value;

            if (state is GetDriverLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is GetDriverFailure) {
              return Center(
                child: Text(
                  state.error,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 18),
                ),
              );
            } else if (state is GetDriverLoaded) {
              final drive = state.drive.isNotEmpty ? state.drive[0] : null;

              if (drive == null) {
                return const Center(
                  child: Text(
                    'drive no encontrado',
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
                          drive.name?.substring(0, 1) ?? 'N',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    drive.name ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    drive.email ?? 'Sin email',
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
                        'Edad: ${drive.years_old ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.cake,
                        color: Color(0xFFEFC300),
                        size: 30,
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
