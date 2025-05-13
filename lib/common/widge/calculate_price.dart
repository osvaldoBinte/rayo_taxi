
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
class CalculatePrice extends StatelessWidget {
  final double bottom;
  final double left;
  final double right;
  final ValueListenable<double> travelDuration;
  final RxString travelPrice;
  final String? fixedPrice;
  final bool useFixedPrice;
  
  const CalculatePrice({
    Key? key,
    this.bottom = 100.0,
    this.left = 20.0,
    this.right = 20.0,
    required this.travelDuration,
    required this.travelPrice,
    this.fixedPrice,
    this.useFixedPrice = false,
  }) : super(key: key);

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
                  if (useFixedPrice && fixedPrice != null)
                    Text(
                      fixedPrice!,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )
                  else
                    Obx(() => Text(
                      travelPrice.value.isEmpty
                          ? 'Calculando precio...'
                          : travelPrice.value,
                      style: const TextStyle(
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
    );
  }
}