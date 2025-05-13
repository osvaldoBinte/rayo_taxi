import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapLocationSelectorController extends GetxController {
  late GoogleMapController mapController;
  var currentAddress = ''.obs;
  var selectedLocation = Rxn<LatLng>();
  var isLoading = false.obs;
  var centerLocation = const LatLng(20.5888, -100.3899).obs;

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
      // Obtener la posición de la cámara actual
      final cameraPosition = await mapController.getVisibleRegion();
      final center = LatLng(
        (cameraPosition.northeast.latitude + cameraPosition.southwest.latitude) / 2,
        (cameraPosition.northeast.longitude + cameraPosition.southwest.longitude) / 2,
      );
      
      selectedLocation.value = center;
      
      // Obtener la dirección usando las coordenadas del centro
      List<Placemark> placemarks = await placemarkFromCoordinates(
        center.latitude,
        center.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        // Construir la dirección con más detalles
        var addressParts = <String>[];
        
        if (place.street?.isNotEmpty ?? false) {
          addressParts.add(place.street!);
        }
        if (place.subLocality?.isNotEmpty ?? false) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality?.isNotEmpty ?? false) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea?.isNotEmpty ?? false) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country?.isNotEmpty ?? false) {
          addressParts.add(place.country!);
        }
        
        currentAddress.value = addressParts.join(', ');
      } else {
        currentAddress.value = 'Ubicación no encontrada';
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
    }
  }
}