import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/mapa/presentation/midireccion_page.dart';
import 'package:rayo_taxi/features/mapa/presentation/page/mapa/destino_page.dart';
import 'package:rayo_taxi/features/mapa/presentation/page/travel_route.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/TravelAlert/travel_alert_getx.dart';

class SelectMap extends StatefulWidget {
  @override
  _SelectMapState createState() => _SelectMapState();
}

class _SelectMapState extends State<SelectMap> {
  final TravelAlertGetx travelAlertGetx = Get.find<TravelAlertGetx>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      travelAlertGetx.fetchCoDetails(FetchgetDetailsEvent());
    });
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
          return MapContent(travelList: state.travels);
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
    if (widget.travelList.isNotEmpty) {
      return TravelRoute(travelList: widget.travelList);
    } else {
      return MidireccionPage();
    }
  }
}
