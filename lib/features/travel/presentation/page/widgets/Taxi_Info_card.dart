import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TaxiInfoCard extends StatelessWidget {
  final double bottom;
  final double left;
  final double right;
  final ValueListenable<double>? travelDuration;
  final RxString? travelPrice;
  final String? fixedPrice;
  final bool useFixedPrice;
  final bool isDriverApproaching;
  final LatLng? driverLocation;
  final LatLng? startLocation;
  final int currentStatus; // Agregar esta propiedad
  final LatLng? endLocation; // Agregar esta propiedad

  const TaxiInfoCard({
    Key? key,
    this.bottom = 150.0,
    this.left = 20.0,
    this.right = 20.0,
    this.travelDuration,
    this.travelPrice,
    this.fixedPrice,
    this.useFixedPrice = false,
    this.isDriverApproaching = false,
    this.driverLocation,
    this.startLocation,
    this.endLocation,
    this.currentStatus = 3,
  }) : super(key: key);

  
  Widget _buildProgressBar(BuildContext context) {
    // Seleccionar la imagen según el estado
    final String imagePath = currentStatus == 4
        ? 'assets/images/mapa/destino.png'
        : 'assets/images/mapa/origen.png';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        FractionallySizedBox(
          widthFactor: calculateProgress(),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          left: calculateProgress() * MediaQuery.of(context).size.width * 0.8,
          top: -12,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(2),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 *
        asin(sqrt(a)) *
        1000; // 2 * R; R = 6371 km, resultado en metros
  }

  String getEstimatedArrivalTime() {
    if (driverLocation == null || startLocation == null) {
      print(
          'TaxiInfo Calculando tiempo - Ubicaciones: driver=$driverLocation, start=$startLocation');
      return "calculando...";
    }

    try {
      // Usar endLocation en lugar de startLocation para estado 4
      final targetLocation = currentStatus == 4 ? endLocation : startLocation;

      if (targetLocation == null) return "calculando...";

      final distance = calculateDistance(
          driverLocation!.latitude,
          driverLocation!.longitude,
          targetLocation.latitude,
          targetLocation.longitude);

      print('TaxiInfo Distancia calculada: $distance metros');

      final averageSpeed = 30.0 * 1000 / 3600;
      final estimatedSeconds = distance / averageSpeed;
      final minutes = (estimatedSeconds / 60).round();

      print('TaxiInfo Minutos estimados: $minutes');

      if (minutes < 1) {
        return "menos de un minuto";
      } else {
        return "$minutes minutos";
      }
    } catch (e) {
      print('TaxiInfo Error calculando tiempo: $e');
      return "calculando...";
    }
  }

  double calculateProgress() {
  if (driverLocation == null) return 0.0;

  // Usar endLocation en lugar de startLocation para estado 4
  final targetLocation = currentStatus == 4 ? endLocation : startLocation;
  if (targetLocation == null) return 0.0;

  final currentDistance = calculateDistance(
    driverLocation!.latitude,
    driverLocation!.longitude,
    targetLocation.latitude,
    targetLocation.longitude
  );

  final maxDistance = 2000.0;
  double progress = 1.0 - (currentDistance / maxDistance);
  
  if (currentDistance > maxDistance) {
    return 0.1;
  }
  
  if (currentDistance > 100) {
    progress = progress * 0.9;
  }

  return progress.clamp(0.0, 1.0);
}
  Widget _buildTimeText() {
    print('TaxiInfo isDriverApproaching: $isDriverApproaching');
    print('TaxiInfo driverLocation: $driverLocation');
    print('TaxiInfo startLocation: $startLocation');

    if (isDriverApproaching &&
        driverLocation != null &&
        startLocation != null) {
      final tiempo = getEstimatedArrivalTime();
      print('TaxiInfo Tiempo estimado calculado: $tiempo');

      // Mensaje diferente según el estado
      final mensaje = currentStatus == 4
          ? 'Llegarás a tu destino en $tiempo'
          : 'El chofer llegará en $tiempo';

      return Text(
        mensaje,
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.grey[700],
        ),
      );
    } else {
      return Text(
        'Calculando tiempo...',
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.grey[700],
        ),
      );
    }
  }

  Widget _buildPriceText() {
    if (useFixedPrice && fixedPrice != null) {
      return Text(
        fixedPrice!,
        style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    } else if (travelPrice != null) {
      return Obx(() => Text(
            travelPrice!.value.isEmpty
                ? 'Calculando precio...'
                : travelPrice!.value,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ));
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Logo_client.png',
                  height: 40.0,
                  width: 40.0,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Taxi',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      _buildTimeText(),
                    //  _buildPriceText(),
                    ],
                  ),
                ),
              ],
            ),
            if (isDriverApproaching &&
                driverLocation != null &&
                startLocation != null)
              Column(
                children: [
                  const SizedBox(height: 10),
                  _buildProgressBar(context),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
