import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class CurrentTravelController extends GetxController {
  final List<TravelAlertModel> travelList;

  CurrentTravelController({required this.travelList});

  RxSet<Marker> markers = <Marker>{}.obs;
  RxSet<Polyline> polylines = <Polyline>{}.obs;
  Rx<LatLng?> startLocation = Rx<LatLng?>(null);
  Rx<LatLng?> endLocation = Rx<LatLng?>(null);
  RxBool isLoading = true.obs;
  RxInt waitingFor = 0.obs;
  RxInt idStatus = 0.obs;
  RxBool isIdStatusSix = false.obs;
  RxBool isIdStatusOne = false.obs;
  // RxString waitingFor = ''.obs;

  GoogleMapController? mapController;
  final LatLng center = const LatLng(20.676666666667, -103.39182);
  final TravelLocalDataSource travelLocalDataSource =
      TravelLocalDataSourceImp();
  StreamSubscription<Position>? positionStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeMap();
  }

@override
void onClose() {
  positionStreamSubscription?.cancel();
  travelList.clear();
  markers.clear();
  polylines.clear();
  super.onClose();
}



  Future<void> _initializeMap() async {
    if (travelList.isNotEmpty) {
      var travelAlert = travelList[0];
      isIdStatusSix.value = travelAlert.id_status == 6;
      isIdStatusOne.value = travelAlert.id_status == 1;
      waitingFor.value = travelAlert.waiting_for ?? 0;

      print('====== travel.status ${ travelAlert.id_status}');
      print('====== travel.waiting_for ${ travelAlert.id_status}');
      print('======  waitingFor.value ${waitingFor.value}');
      print('====== isIdStatusSix ${isIdStatusSix.value}');
      double? startLatitude = double.tryParse(travelAlert.start_latitude);
      double? startLongitude = double.tryParse(travelAlert.start_longitude);
      double? endLatitude = double.tryParse(travelAlert.end_latitude);
      double? endLongitude = double.tryParse(travelAlert.end_longitude);

      if (startLatitude != null &&
          startLongitude != null &&
          endLatitude != null &&
          endLongitude != null) {
        startLocation.value = LatLng(startLatitude, startLongitude);
        endLocation.value = LatLng(endLatitude, endLongitude);

        _addMarker(startLocation.value!, true);
        _addMarker(endLocation.value!, false);

        await _traceRoute();
      } else {
        Get.snackbar('Error', 'Error al convertir coordenadas a números');
      }

      waitingFor.value = travelAlert.waiting_for;
      idStatus.value = travelAlert.id_status;
    }
    isLoading.value = false;
  }
void updateFromNotification(TravelAlertModel updatedTravel) {
  isIdStatusSix.value = updatedTravel.id_status == 6;
  waitingFor.value = updatedTravel.waiting_for ?? 0;
  
  // Para debugging
  print('Actualizando valores:');
  print('isIdStatusSix: ${isIdStatusSix.value}');
  print('waitingFor: ${waitingFor.value}');
}
  LatLngBounds createLatLngBoundsFromMarkers() {
    if (markers.isEmpty) {
      return LatLngBounds(
        northeast: center,
        southwest: center,
      );
    }

    List<LatLng> positions = markers.map((m) => m.position).toList();
    double x0, x1, y0, y1;
    x0 = x1 = positions[0].latitude;
    y0 = y1 = positions[0].longitude;
    for (LatLng pos in positions) {
      if (pos.latitude > x1) x1 = pos.latitude;
      if (pos.latitude < x0) x0 = pos.latitude;
      if (pos.longitude > y1) y1 = pos.longitude;
      if (pos.longitude < y0) y0 = pos.longitude;
    }
    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  void _addMarker(LatLng latLng, bool isStartPlace) {
    MarkerId markerId =
        isStartPlace ? MarkerId('start') : MarkerId('destination');
    String title = isStartPlace ? 'Inicio' : 'Destino';

    markers.removeWhere((m) => m.markerId == markerId);
    markers.add(
      Marker(
        markerId: markerId,
        position: latLng,
        infoWindow: InfoWindow(title: title),
      ),
    );
  }

  Future<void> _traceRoute() async {
    if (startLocation.value != null && endLocation.value != null) {
      try {
        await travelLocalDataSource.getRoute(
            startLocation.value!, endLocation.value!);
        String encodedPoints = await travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            travelLocalDataSource.decodePolyline(encodedPoints);

        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ),
        );
      } catch (e) {
        Get.snackbar('Error', 'Error al trazar la ruta');
      }
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (startLocation.value != null) {
      mapController?.moveCamera(
        CameraUpdate.newLatLngZoom(startLocation.value!, 14.0),
      );
    }
  }

  void updateWaitingFor(int newStatus) {
    waitingFor.value = newStatus;
  }

  void updateIdStatus(int newStatus) {
    idStatus.value = newStatus;
  }
}
