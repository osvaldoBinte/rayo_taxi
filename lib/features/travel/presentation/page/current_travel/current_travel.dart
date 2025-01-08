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
import 'package:rayo_taxi/features/travel/presentation/page/widgets/cancel_travel_button.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/info_button_widget.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/waiting_status_widget.dart';
import 'package:speech_bubble/speech_bubble.dart';

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
                  myLocationEnabled: true,
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
            Obx(() => WaitingStatusWidget(
                  isIdStatusSix: controller.isIdStatusSix.value,
                  waitingFor: controller.waitingFor.value,
                  notificationService: notificationService,
                )),
            InfoButtonWidget(
              travelList: widget.travelList,
            ),
           CancelTravelButton(
  travelId: widget.travelList[0].id.toString(),
  idStatus: widget.travelList[0].id_status,
  navigatorKey: Get.key,
),
          ],
        ),
      ),
    );
  }
}
