import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/addTravelController.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../AuthS/connectivity_service.dart';
import '../../Travelgetx/TravelAlert/travel_alert_getx.dart';

class MapScreen extends StatelessWidget {
 final TextEditingController endController;
  final String startAddress;
  final LatLng? startLatLng;
  final LatLng? endLatLng; // Nueva propiedad
  final String endAddress; // Nueva propiedad

  MapScreen({
    required this.endController,
    required this.startAddress,
    required this.startLatLng,
    this.endLatLng,
    this.endAddress = '',
  }) {
    if (Get.isRegistered<MapController>()) {
      Get.delete<MapController>();
    }
  }

  @override
  Widget build(BuildContext context) {
   final MapController controller = Get.put(MapController(
      endControllerText: endController.text,
      startAddress: startAddress,
      startLatLng: startLatLng,
    ));
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() => GoogleMap(
                  onMapCreated: controller.onMapCreated,
                  markers: controller.markers.value,
                  polylines: controller.polylines.value,
                  initialCameraPosition: CameraPosition(
                    target: controller.center.value,
                    zoom: 15,
                  ),
                )),
            Positioned(
              top: 20.0,
              left: 10.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30.0,
                  ),
                  onPressed: () {
                    Future.delayed(Duration.zero, () {
                      Navigator.pushNamed(
                        context,
                        RoutesNames.homePage,
                        arguments: {'selectedIndex': 1},
                      );
                    });
                  },
                ),
              ),
            ),
            Positioned(
              top: 70.0,
              left: 10.0,
              right: 10.0,
              child: GestureDetector(
                onTap: () {
                  controller.showDirectionModal(context, controller);
                },
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Icon(
                            Icons.circle,
                            color: Colors.black,
                            size: 12.0,
                          ),
                          Container(
                            height: 40.0,
                            width: 2.0,
                            color: Colors.grey,
                          ),
                          Icon(
                            Icons.square,
                            color: Colors.black,
                            size: 12.0,
                          ),
                        ],
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          children: [
                            Obx(() => Text(
                                  controller.startAddressText.value.isNotEmpty
                                      ? controller.startAddressText.value
                                      : "Dirección de inicio",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500),
                                )),
                            Divider(color: Colors.grey, thickness: 1.0),
                            Obx(() => Text(
                                  controller.endAddressText.value.isNotEmpty
                                      ? controller.endAddressText.value
                                      : "¿A dónde vas?",
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100.0, // Ajusta la posición según necesites
              left: 20.0,
              right: 20.0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Logo_client.png',
                      height: 40.0,
                      width: 40.0,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'taxi',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 5.0),
                          ValueListenableBuilder<double>(
                            valueListenable: controller.travelDuration,
                            builder: (context, duration, child) {
                              return Text(
                                'El tiempo estimado de tu viaje es de ${duration.toStringAsFixed(0)} minutos',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.grey[700],
                                ),
                              );
                            },
                          ),
                          Obx(() => Text(
                                controller.travelPrice.value.isEmpty
                                    ? 'Calculando precio...'
                                    : controller.travelPrice.value,
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20.0,
              left: 20.0,
              right: 20.0,
              child: Obx(() => ElevatedButton(
                    onPressed: () => controller.showRouteDetails(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.buttonColormap,
                      padding: EdgeInsets.symmetric(vertical: 18.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions, color: Colors.white),
                        SizedBox(width: 10.0),
                        Text(
                          controller.buttonText.value,
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              right: 25.0,
              child: FloatingActionButton(
                onPressed: controller.getUserLocation,
                child: Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
