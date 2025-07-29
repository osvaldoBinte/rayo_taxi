import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/notification_service.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel/current_travel_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel/emergency_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/waiting_status_widget.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/info_button_widget.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/rejectTravelOffer/rejectTravelOffer_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';

class CurrentTravel extends StatefulWidget {
  final List<TravelAlertModel> travelList;

  CurrentTravel({required this.travelList});

  @override
  _TravelRouteState createState() => _TravelRouteState();
}

class _TravelRouteState extends State<CurrentTravel> {
  late CurrentTravelController controller;
  late EmergencyController emergencyController;

  final NotificationController notificationController =
      Get.find<NotificationController>();
  final notificationService = Get.find<NotificationService>();
  
  final DeleteTravelGetx _deleteTravelGetx = Get.find<DeleteTravelGetx>();
  final RejecttravelofferGetx _rejectTravelOfferGetx =
      Get.find<RejecttravelofferGetx>();
  final travelAlertGetx = Get.find<TravelsAlertGetx>();
  final currentTravelGetx = Get.find<CurrentTravelGetx>();

  @override
  void initState() {
    super.initState();
    controller = Get.put(CurrentTravelController(travelList: widget.travelList));
    emergencyController = Get.put(EmergencyController());
  }

  @override
  void dispose() {
    Get.delete<CurrentTravelController>();
    Get.delete<EmergencyController>();
    super.dispose();
  }
  
  void _handleCancelTravel() {
    final idStatus = widget.travelList[0].id_status;
    if (idStatus == 1) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Cancelar Viaje',
        text: '¿Deseas cancelar este viaje?',
        confirmBtnText: 'Sí, cancelar',
        cancelBtnText: 'No',
        showCancelBtn: true,
        onConfirmBtnTap: () {
          _deleteTravelGetx.deleteTravel(DeleteTravelEvent(widget.travelList[0].id.toString()));
          ever(_deleteTravelGetx.state, (DeleteState state) {
            if (state is DeleteCreatedSuccessfully) {
              currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
              travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
            }
          });
          Navigator.pop(Get.context!);
        },
      );
    } else if (idStatus == 3) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Cancelar Viaje',
        text: '¿Deseas cancelar el viaje?',
        confirmBtnText: 'Sí, rechazar',
        cancelBtnText: 'No',
        showCancelBtn: true,
        onConfirmBtnTap: () async {
          final state = currentTravelGetx.state.value;

          if (state is! TravelAlertLoaded) {
            print("Error: No travel data available.");
            Navigator.pop(Get.context!);
            return;
          }

          final travel2 = state.travel.first;
          final travelId = travel2.id;
          final driverId = int.parse(travel2.id_travel_driver);

          try {
            Navigator.pop(Get.context!);
            
            final travel = TravelwithtariffEntitie(
              driverId: driverId,
              travelId: travelId,
            );
            final event = RejectTravelofferEventEvent(travel: travel);
            await Get.find<RejecttravelofferGetx>().rejecttravelofferGetx(event);

            CustomSnackBar.showSuccess(
              'Éxito',
              'El rechazo de la oferta de viaje se realizó correctamente',
            );
            await currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
          } catch (error) {
            CustomSnackBar.showError(
              'Error',
              'Hubo un problema al rechazar la oferta de viaje',
            );
          }
        },
      );
    }
  }
  
  // Función para crear el botón de emergencia
  Widget _buildEmergencyButton() {
    return GestureDetector(
      onTapDown: (_) => emergencyController.onEmergencyTapDown(),
      onTapUp: (_) => emergencyController.onEmergencyTapUp(),
      onTapCancel: () => emergencyController.onEmergencyTapCancel(),
      child: AnimatedBuilder(
        animation: emergencyController.animationController,
        builder: (context, child) {
          return ClipOval(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.emergency,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.emergency.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Obx(() => Stack(
                alignment: Alignment.center,
                children: [
                  if (emergencyController.isPressed.value)
                    CircularProgressIndicator(
                      value: emergencyController.animationController.value,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 4,
                    ),
                  Icon(
                    Icons.local_hospital,
                    color: Theme.of(context).colorScheme.buttontext,
                    size: 20,
                  ),
                ],
              )),
            ),
          );
        },
      ),
    );
  }
  
  // Función para crear la barra de progreso para TaxiInfoCard
  Widget _buildProgressBar(BuildContext context) {
    final String imagePath = controller.idStatus.value == 4
        ? 'assets/images/mapa/destino.png'
        : 'assets/images/mapa/origen.png';

    // Calcular el progreso
    double calculateProgress() {
      if (controller.driverLocation.value == null) return 0.0;

      final targetLocation = controller.idStatus.value == 4 
          ? controller.endLocation.value 
          : controller.startLocation.value;
          
      if (targetLocation == null) return 0.0;

      final currentDistance = _calculateDistance(
        controller.driverLocation.value!.latitude,
        controller.driverLocation.value!.longitude,
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
  
  // Función para calcular distancia
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }
  
  // Función para obtener el tiempo estimado de llegada
  String _getEstimatedArrivalTime() {
    if (controller.driverLocation.value == null || controller.startLocation.value == null) {
      return "calculando...";
    }

    try {
      final targetLocation = controller.idStatus.value == 4 
          ? controller.endLocation.value 
          : controller.startLocation.value;

      if (targetLocation == null) return "calculando...";

      final distance = _calculateDistance(
          controller.driverLocation.value!.latitude,
          controller.driverLocation.value!.longitude,
          targetLocation.latitude,
          targetLocation.longitude);

      final averageSpeed = 30.0 * 1000 / 3600;
      final estimatedSeconds = distance / averageSpeed;
      final minutes = (estimatedSeconds / 60).round();

      if (minutes < 1) {
        return "menos de un minuto";
      } else {
        return "$minutes minutos";
      }
    } catch (e) {
      return "calculando...";
    }
  }
  
  // Función para crear el texto del tiempo
  Widget _buildTimeText() {
    if (controller.driverLocation.value != null && controller.startLocation.value != null) {
      final tiempo = _getEstimatedArrivalTime();
      
      final mensaje = controller.idStatus.value == 4
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
  
  // Crear el TaxiInfoCard sin Positioned
  Widget _buildTaxiInfoCard(BuildContext context) {
    return Container(
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
                  ],
                ),
              ),
            ],
          ),
          if (controller.driverLocation.value != null && 
              controller.startLocation.value != null)
            Column(
              children: [
                const SizedBox(height: 10),
                _buildProgressBar(context),
              ],
            ),
        ],
      ),
    );
  }
  
  // Botón de cancelar viaje
  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: () => _handleCancelTravel(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.Statuscancelled,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Cancelar Viaje',
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.buttontext,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // GoogleMap en la parte inferior del Stack
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
                
            // Barra de estado en la parte superior
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
            
            // Widgets de información y control en la parte inferior
            Obx(() {
              print("Current idStatus: ${controller.idStatus.value}");
              
              if (controller.idStatus.value == 3 || controller.idStatus.value == 4) {
                // Mostrar interfaz completa con tarjeta de información
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Botón de emergencia
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 16),
                          child: _buildEmergencyButton(),
                        ),
                        
                        // Tarjeta de información y botón cancelar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // TaxiInfoCard incorporado directamente aquí
                              _buildTaxiInfoCard(context),
                              
                              const SizedBox(height: 16),
                              
                              // Botón de cancelar
                              SizedBox(
                                width: double.infinity,
                                child: _buildCancelButton(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // Mostrar solo el botón de cancelar
                return Positioned(
                  left: 16,
                  right: 16,
                  bottom: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildCancelButton(),
                  ),
                );
              }
            }),
            
            // Widget de estado de espera
            Obx(() => WaitingStatusWidget(
                  isIdStatusSix: controller.isIdStatusSix.value,
                  waitingFor: controller.waitingFor.value,
                  notificationService: notificationService,
                )),
                
            // Botón de información
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