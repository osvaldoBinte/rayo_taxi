import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/notification_service.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/rejectTravelOffer/rejectTravelOffer_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';

class WaitingStatusWidget extends StatelessWidget {
  final bool isIdStatusSix;
  final int waitingFor;
  final NotificationService notificationService;

  const WaitingStatusWidget({
    Key? key,
    required this.isIdStatusSix,
    required this.waitingFor,
    required this.notificationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isIdStatusSix) {
      return SizedBox.shrink();
    }

    if (waitingFor == 2) {
      return _buildWaitingMessage(
          'Esperando respuesta del Chofer', Colors.orangeAccent, context);
    } else if (waitingFor == 1) {
      return _buildCounterOfferMessage(context);
    }

    return SizedBox.shrink();
  }

  void _showConfirmationDialog(BuildContext context) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: '¿Estás seguro?',
      text: '¿Deseas rechazar esta oferta?',
      confirmBtnText: 'Sí, rechazar',
      cancelBtnText: 'No, cancelar',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () {
        Navigator.pop(context);
        CancelTravel(context);
      },
    );
  }

  void CancelTravel(BuildContext context) async {
    final currentTravelGetx = Get.find<CurrentTravelGetx>();

    final state = currentTravelGetx.state.value;

    if (state is! TravelAlertLoaded) {
      print("Error: No travel data available.");
      return;
    }

    final travel = state.travel.first;
    final travelId = travel.id;
    final driverId = int.parse(travel.id_travel_driver);
    print('-------- $driverId travel $travelId tarifa ');
    final travelAlertGetx = Get.find<TravelsAlertGetx>();
    travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

    try {
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
      currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
    } catch (error) {
      Get.back();
      CustomSnackBar.showError(
        'Error',
        'Hubo un problema al rechazar la oferta de viaje',
      );
    }
  }

  Widget _buildWaitingMessage(
      String message, Color color, BuildContext context) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _showConfirmationDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Rechazar oferta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterOfferMessage(BuildContext context) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Esperando tu contra oferta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                GestureDetector(
                  onTap: () {
                    notificationService.showNewPriceDialog(context);
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.message,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}