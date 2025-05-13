import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/FloatingNotificationButton.dart';
import 'package:rayo_taxi/common/notification_service.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel/current_travel_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel/emergency_button.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/Taxi_Info_card.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/cancel_travel_button.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/info_button_widget.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/waiting_status_widget.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CurrentTravel extends StatefulWidget {
  final List<TravelAlertModel> travelList;

  CurrentTravel({required this.travelList});

  @override
  _TravelRouteState createState() => _TravelRouteState();
}

class _TravelRouteState extends State<CurrentTravel> {
  late CurrentTravelController controller;

  final NotificationController notificationController =
      Get.find<NotificationController>();
  final notificationService = Get.find<NotificationService>();

  @override
  void initState() {
    super.initState();
    controller =
        Get.put(CurrentTravelController(travelList: widget.travelList));
  }

  @override
  void dispose() {
    Get.delete<CurrentTravelController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
  body: SafeArea(
    child: Stack(
      children: [
        Obx(() => GoogleMap(
              onMapCreated: controller.onMapCreated,
              initialCameraPosition: CameraPosition(
                target: controller.startLocation.value ?? controller.center,
                zoom: 12.0,
              ),
              markers: controller.markers.value,
              polylines: controller.polylines.value,
              myLocationEnabled: false,
              myLocationButtonEnabled: true,
            )),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ' ${widget.travelList[0].status}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
Obx(() =>
  controller.idStatus.value == 3 || controller.idStatus.value == 4
      ?Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 16),
                  child: EmergencyButton(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TaxiInfoCard(
                        isDriverApproaching: true,
                        driverLocation: controller.driverLocation.value,
                        startLocation: controller.startLocation.value,
                        endLocation: controller.endLocation.value,
                        currentStatus: controller.idStatus.value,
                        travelDuration: controller.travelDuration,
                        travelPrice: controller.travelPrice,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, 
                        child: CancelTravelButton(
                          travelId: widget.travelList[0].id.toString(),
                          idStatus: widget.travelList[0].id_status,
                          navigatorKey: Get.key,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
      :  Positioned(
          left: 16,
          right: 16,
          bottom: 80,
          child: CancelTravelButton(
            travelId: widget.travelList[0].id.toString(),
            idStatus: widget.travelList[0].id_status,
            navigatorKey: Get.key,
          ),
        ),
),
        Obx(() => WaitingStatusWidget(
              isIdStatusSix: controller.isIdStatusSix.value,
              waitingFor: controller.waitingFor.value,
              notificationService: notificationService,
            )),
        Positioned(
          top: 150,
          left: 16,
          child: InfoButtonWidget(
            travelList: widget.travelList,
          ),
        ),
      ],
    ),
  ),
);
}
}