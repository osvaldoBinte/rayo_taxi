import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapLocationSelectorController extends GetxController {
  late GoogleMapController mapController;
  var currentAddress = ''.obs;
  var selectedLocation = Rxn<LatLng>();
  var isLoading = false.obs;
  var centerLocation = const LatLng(20.676666666667, -103.39182).obs;

  void initializeLocation(LatLng? initialLocation) {
    if (initialLocation != null) {
      centerLocation.value = initialLocation;
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (centerLocation.value != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(centerLocation.value),
      );
    }
  }

  Future<void> onCameraIdle(BuildContext context) async {
    isLoading.value = true;

    try {
      LatLng center = await mapController.getLatLng(
        ScreenCoordinate(
          x: MediaQuery.of(context).size.width ~/ 2,
          y: MediaQuery.of(context).size.height ~/ 2,
        ),
      );
      selectedLocation.value = center;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        center.latitude,
        center.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        currentAddress.value =
            '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      print('Error getting address: $e');
      currentAddress.value = 'Error al obtener dirección';
    }

    isLoading.value = false;
  }

  void confirmLocation(Function(String, LatLng) onLocationSelected) {
    if (selectedLocation.value != null) {
      onLocationSelected(currentAddress.value, selectedLocation.value!);
      Get.back();
      Get.back();
    }
  }
}
