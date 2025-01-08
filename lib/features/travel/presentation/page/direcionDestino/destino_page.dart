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
      onCameraIdle: controller.onCameraIdle,
      initialCameraPosition: CameraPosition(
        target: controller.currentLatLng.value ?? 
            const LatLng(20.6596988, -103.3496092),
        zoom: 15,
      ),
      markers: controller.markers, 
    )),
          
       Center(
      child: Icon(
        Icons.location_on,
        size: 48,
        color: Colors.black.withOpacity(0.5), 
      ),
    ),
    
   
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
                  SizedBox(height: 16),
                  TextField(
                    controller: controller.mainDestinoController,
                    focusNode: controller.mainFocusNode,
                    onTap: () => controller.showSearchModal(context),
                    decoration: InputDecoration(
                      hintText: '¿A dónde quieres ir?',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
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
                            ? () => controller.navigateToMapScreen(context)
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
class MarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)  // Empezar desde arriba
      ..lineTo(size.width, size.height / 3)  // Línea a la derecha
      ..quadraticBezierTo(
        size.width / 2, size.height / 2,  // Punto de control
        size.width / 2, size.height  // Punto final
      )
      ..quadraticBezierTo(
        size.width / 2, size.height / 2,  // Punto de control
        0, size.height / 3  // Punto final
      )
      ..close();

    // Dibujar sombra
    canvas.drawShadow(path, Colors.black, 4, true);
    // Dibujar pin
    canvas.drawPath(path, paint);

    // Círculo blanco en el centro
    final Paint circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 3),
      size.width / 6,
      circlePaint
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
