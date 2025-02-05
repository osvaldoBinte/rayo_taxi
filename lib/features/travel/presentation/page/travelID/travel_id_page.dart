import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travelID/travel_id_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/info_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TravelIdPage extends StatelessWidget {
  final TravelAlertModel travel;
  final String tag;
  final bool showInfoButton;
  final bool isPreview;

  TravelIdPage({
    required this.travel,
    String? tag,
    this.showInfoButton = true,
    this.isPreview = false,
  }) : this.tag = tag ?? travel.hashCode.toString();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      TravelController(travel: travel, isPreview: isPreview),  // Pass isPreview to controller
      tag: tag,
      permanent: false,
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() => controller.isLoading.value
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: controller.onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: controller.startLocation.value ?? controller.center,
                      zoom: 12.0,
                    ),
                    markers: controller.markers.value,
                    polylines: controller.polylines.value,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: !isPreview, 
                    scrollGesturesEnabled: !isPreview, 
                  )),
            if (showInfoButton)
              InfoButtonWidget(
                travel: travel,
              ),
          ],
        ),
      ),
    );
  }
}