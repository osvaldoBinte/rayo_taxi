import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:speech_bubble/speech_bubble.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';

class InfoButtonWidget extends StatelessWidget {
  final TravelAlertModel? travel;
  final List<TravelAlertModel>? travelList;
  final String imagePath;

  const InfoButtonWidget({
    Key? key,
    this.travel,
    this.travelList,
    this.imagePath = 'assets/images/viajes/taxi.png',
  }) : assert(travel != null || travelList != null, 
             'Debe proporcionar travel o travelList'),
       super(key: key);

  void _showInfoDialog(BuildContext context) {
    String text;
    
    if (travel != null) {
      // Usar el viaje individual si está disponible
      var importe = (travel!.id_status == 1 || travel!.id_status == 2) 
          ? travel!.cost 
          : travel!.tarifa;
      
      text = 'Conductor: ${travel!.driver}\n'
             'Fecha: ${travel!.date}\n'
             'Importe: \$${importe} MXN';
    } else if (travelList != null && travelList!.isNotEmpty) {
      var firstTravel = travelList![0];
  var importe = (firstTravel.id_status == 1 || firstTravel.id_status == 2)
      ? firstTravel.cost 
      : firstTravel.tarifa;

  text = 'Chofer: ${firstTravel.driver}\n'
         'Fecha: ${firstTravel.date}\n'
         'Importe: \$${importe} MXN';

    } else {
      text = 'Sin información disponible';
    }

    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      title: 'Información del Viaje',
      text: text,
      confirmBtnText: 'Cerrar',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpeechBubble(
            nipLocation: NipLocation.BOTTOM,
            color: Theme.of(context).colorScheme.buttonColormap,
            borderRadius: 20,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Información',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(height: 5),
          IconButton(
            icon: Image.asset(
              imagePath,
              width: 40,
              height: 40,
            ),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
    );
  }
}