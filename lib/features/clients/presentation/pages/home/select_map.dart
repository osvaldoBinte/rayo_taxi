import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/TravelListScreen.dart';
import 'package:rayo_taxi/features/travel/presentation/page/mapa.dart'; // MapScreen
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/mapa/destino_page.dart';

class SelectMap extends StatefulWidget {
  @override
  _SelectMapState createState() => _SelectMapState();
}

class _SelectMapState extends State<SelectMap> {
  final TravelAlertGetx travelAlertGetx = Get.find<TravelAlertGetx>();

  @override
  void initState() {
    super.initState();
    travelAlertGetx.fetchCoDetails(FetchgetDetailsssEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final state = travelAlertGetx.state.value;
        if (state is TravelAlertLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is TravelAlertLoaded) {
          return MapContent(travelList: state.travel);
        } else if (state is TravelAlertFailure) {
          return MapContent(travelList: []);
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      }),
    );
  }
}

class MapContent extends StatefulWidget {
  final List<TravelAlertModel> travelList;

  MapContent({required this.travelList});

  @override
  _MapContentState createState() => _MapContentState();
}

class _MapContentState extends State<MapContent> {
  // Aquí puedes definir tus variables y métodos

  @override
  Widget build(BuildContext context) {
    if (widget.travelList.isNotEmpty) {
      // Mostrar contenido de MapScreen22
      return MapScreen22(travelList: widget.travelList);
    } else {
      // Mostrar contenido de MapScreen
      return DestinoPage();
    }
  }
}
