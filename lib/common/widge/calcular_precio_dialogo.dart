
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
class CalcularPrecioDialogo extends StatelessWidget {
  final ValueListenable<double> travelDuration;
  final RxString travelPrice;
  final double bottom;
  final double left;
  final double right;
  
  const CalcularPrecioDialogo({
    Key? key,
    required this.travelDuration,
    required this.travelPrice,
    this.bottom = 100.0,
    this.left = 20.0,
    this.right = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the CurrentTravelGetx to use internally
    final CurrentTravelGetx travelGetx = Get.find<CurrentTravelGetx>();
    
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
        child: Row(
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
                  ValueListenableBuilder<double>(
                    valueListenable: travelDuration,
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
                  Builder(
                    builder: (context) {
                      try {
                        final state = travelGetx.state.value;
                        if (state is TravelAlertLoaded && state.travel.isNotEmpty) {
                          return Text(
                            '\$${state.travel.first.cost} MXN',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          );
                        }
                      } catch (e) {
                        print("Error showing price: $e");
                      }
                      
                      return Obx(() => Text(
                        travelPrice.value.isEmpty
                            ? 'Calculando precio...'
                            : travelPrice.value,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}