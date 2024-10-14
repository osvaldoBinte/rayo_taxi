import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/mapa/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/mapa/domain/entities/travel.dart';
import 'package:rayo_taxi/features/mapa/presentation/getx/travel/travel_getx.dart';
import '../../../../connectivity_service.dart';
class MapWidget extends StatefulWidget {
  final Set<gmaps.Marker> markers;
  final Set<Polyline> polylines;
  final LatLng center;
  final Function(GoogleMapController) onMapCreated;

  const MapWidget({
    Key? key,
    required this.markers,
    required this.polylines,
    required this.center,
    required this.onMapCreated,
  }) : super(key: key);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: widget.onMapCreated,
      initialCameraPosition: CameraPosition(
        target: widget.center,
        zoom: 11.0,
      ),
      markers: widget.markers,
      polylines: widget.polylines,
    );
  }
}
