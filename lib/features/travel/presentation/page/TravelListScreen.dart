import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/mapa_page.dart';
import 'package:rayo_taxi/main.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../connectivity_service.dart';

class MapScreen22 extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen22> {
  late GoogleMapController _mapController;
  final TravelGetx _travelGetx = Get.find<TravelGetx>();
  final DeleteTravelGetx _deleteTravelGetx = Get.find<DeleteTravelGetx>();
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();
  final TravelAlertGetx _travelAlertGetx = Get.find<TravelAlertGetx>();

  Set<gmaps.Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _startLocation;
  LatLng? _endLocation;
  LatLng _center = const LatLng(20.676666666667, -103.39182);
  String _buttonText = "Buscar conductor";
  TravelLocalDataSource _travelLocalDataSource = TravelLocalDataSourceImp();

  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();

    // Inicializa y obtiene los detalles del viaje
    _travelAlertGetx.fetchCoDetails(FetchgetDetailsssEvent());

    // Escucha cambios en el estado de TravelAlertGetx
    ever(_travelAlertGetx.state, (state) {
      if (state is TravelAlertLoaded) {
        if (state.travel.isNotEmpty) {
          // Tomamos el primer viaje de la lista
          var travelAlert = state.travel[0];

          // Convertimos las coordenadas a double
          double? startLatitude = double.tryParse(travelAlert.start_latitude);
          double? startLongitude = double.tryParse(travelAlert.start_longitude);
          double? endLatitude = double.tryParse(travelAlert.end_latitude);
          double? endLongitude = double.tryParse(travelAlert.end_longitude);

          if (startLatitude != null &&
              startLongitude != null &&
              endLatitude != null &&
              endLongitude != null) {
            // Asignamos las coordenadas de inicio y fin
            _startLocation = LatLng(startLatitude, startLongitude);
            print('_startLocation: $_startLocation');

            _endLocation = LatLng(endLatitude, endLongitude);
            print('_endLocation: $_endLocation');

            // Agregamos marcadores en el mapa
            _addMarker(_startLocation!, true);
            _addMarker(_endLocation!, false);

            // Trazamos la ruta entre los puntos
            _traceRoute();
          } else {
            // Manejo si alguna conversión falla
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al convertir coordenadas a números')),
            );
          }
        }
      } else if (state is TravelAlertFailure) {
        // Manejo de errores
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${state.error}')),
        );
      }
    });

    // Manejo de conectividad
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        if (result == ConnectivityResult.none) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se perdió la conectividad Wi-Fi'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addMarker(LatLng latLng, bool isStartPlace) {
    setState(() {
      if (isStartPlace) {
        _markers.removeWhere((m) => m.markerId.value == 'start');
        _markers.add(
          gmaps.Marker(
            markerId: MarkerId('start'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Inicio'),
          ),
        );
        _startLocation = latLng;
      } else {
        _markers.removeWhere((m) => m.markerId.value == 'destination');
        _markers.add(
          gmaps.Marker(
            markerId: MarkerId('destination'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Destino'),
          ),
        );
        _endLocation = latLng;
      }

      if (_startLocation != null && _endLocation != null) {
        _traceRoute();
      }
    });
  }

  Future<int?> _getSavedTravelId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_travel_id');
  }

  Future<void> _traceRoute() async {
    if (_startLocation != null && _endLocation != null) {
      try {
        await _travelLocalDataSource.getRoute(_startLocation!, _endLocation!);
        String encodedPoints = await _travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _travelLocalDataSource.decodePolyline(encodedPoints);
        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: PolylineId('route'),
            points: polylineCoordinates,
            color: Colors.blue,
            width: 5,
          ));
        });
      } catch (e) {
        print('Error al trazar la ruta: $e');
      }
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            MapWidget(
              markers: _markers,
              polylines: _polylines,
              center: _center,
              onMapCreated: _onMapCreated,
            ),
            
            // Eliminamos los TextFields ya que no los necesitamos
          ],
        ),
      ),
    );
  }
}
