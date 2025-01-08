import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/MapLocationSelector/map_location_selector_controller.dart';
class MapLocationSelectorModal extends StatelessWidget {
  final bool isStartLocation;
  final Function(String address, LatLng location) onLocationSelected;
  final LatLng? initialLocation;

  MapLocationSelectorModal({
    required this.isStartLocation,
    required this.onLocationSelected,
    this.initialLocation,
  });

  Widget buildCenterMarker() {
    return const Center(
      child: Icon(
        Icons.location_on,
        size: 50,
        color: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MapLocationSelectorController());
    controller.initializeLocation(initialLocation);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: AbsorbPointer(
                absorbing: false,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: controller.centerLocation.value,
                        zoom: 15,
                      ),
                      onMapCreated: controller.onMapCreated,
                      onCameraIdle: () => controller.onCameraIdle(context),
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                    ),
                    buildCenterMarker(),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.card,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      isStartLocation ? 'Seleccionar punto de inicio' : 'Seleccionar destino',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Obx(() => controller.isLoading.value
                    ? CircularProgressIndicator()
                    : Text(controller.currentAddress.value, 
                        style: TextStyle(fontSize: 16))),
                  SizedBox(height: 16),
                  Obx(() => ElevatedButton(
                    onPressed: controller.selectedLocation.value == null 
                      ? null 
                      : () => controller.confirmLocation(onLocationSelected),
                    child: Text('Confirmar ubicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.buttonColormap,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}