import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_place_details_and_move_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_place_predictions_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_search_history_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/save_search_history_usecase.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/addTravelController.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/mapa.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/presentation/page/direcionDestino/search_modal.dart';

class DestinoPage extends StatelessWidget {
  final DestinoController controller = Get.find<DestinoController>();
  Widget buildCenterMarker() {
    return Center(
      child: Transform.translate(
        offset: Offset(0, -25),
        child: Image.asset(
          'assets/images/mapa/marker-destino.png',
          width: 50,
          height: 50,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() => GoogleMap(
                onMapCreated: (GoogleMapController mapController) {
                  controller.mapController = mapController;
                  controller.getUserAddress();
                },
                onCameraMove: controller.onCameraMove,
                initialCameraPosition: CameraPosition(
                  target: controller.currentLatLng.value ??
                      const LatLng(20.5888, -100.389),
                  zoom: 15,
                ),
                markers: controller.markers,
              )),
          buildCenterMarker(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fija tu destino',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Arrastra el mapa para mover el marcador',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: controller.mainDestinoController,
                    focusNode: controller.mainFocusNode,
                    onTap: () => controller.showSearchModal(context),
                    decoration: InputDecoration(
                      hintText: '¿A dónde quieres ir?',
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/images/mapa/destino.png',
                          width: 5,
                          height: 5,
                        ),
                      ),
                      suffixIcon: Icon(
                        Icons.search,
                        color: Colors.grey,
                      ),
                    ),
                    readOnly: true,
                  ),
                  SizedBox(height: 16),
                  Obx(() {
                    bool isEnabled =
                        controller.selectedDescription.value != null &&
                            controller.selectedDescription.value!.isNotEmpty;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isEnabled
                            ? () => controller.navigateToMapScreen()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isEnabled ? Colors.black : Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          'Confirmar destino',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 75),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
