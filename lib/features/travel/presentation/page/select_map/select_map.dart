import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel/current_travel.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/mapa.dart'; // MapScreen
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/direcionDestino/destino_page.dart';

class SelectMap extends StatefulWidget {
  @override
  _SelectMapState createState() => _SelectMapState();
}

class _SelectMapState extends State<SelectMap> {
  final CurrentTravelGetx currentTravelGetx = Get.find<CurrentTravelGetx>();

  @override
  void initState() {
    super.initState();
    currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final state = currentTravelGetx.state.value;
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
  @override
  Widget build(BuildContext context) {
    print("Contenido de travelList: ${widget.travelList}");
    if (widget.travelList.isNotEmpty) {
      return CurrentTravel(travelList: widget.travelList);
    } else {
      return DestinoPage();
    }
  }
}
