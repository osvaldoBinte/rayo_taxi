import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../../../connectivity_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  
  late GoogleMapController _mapController;
  final TravelGetx _travelGetx = Get.find<TravelGetx>();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int _markerCount = 0;
  LatLng? _startLocation;
  LatLng? _endLocation;
  LatLng _center = const LatLng(20.676666666667, -103.39182);
  String _buttonText = "buscar conductor";
  List<dynamic> _predictions = [];
  TextEditingController _searchController = TextEditingController();
  TravelLocalDataSource _travelLocalDataSource = TravelLocalDataSourceImp();

  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _searchController.addListener(() {
      _searchPlace(_searchController.text);
    });

    // Escuchar cambios en la conectividad
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        if (result == ConnectivityResult.none) {
          // Mostrar SnackBar cuando se pierda la conexión Wi-Fi
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

  void _addMarker(LatLng latLng) {
    setState(() {
      if (_markerCount == 1) { // Permitir solo añadir el destino
        _markers.add(
          Marker(
            markerId: MarkerId('destination'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Buscar'),
          ),
        );
        _endLocation = latLng;
        _buttonText = "Buscar";

        _traceRoute();
      }

      _markerCount++;
    });
  }

  Future<void> _traceRoute() async {
    if (_startLocation != null && _endLocation != null) {
      try {
        await _travelLocalDataSource.getRoute(_startLocation!, _endLocation!);
        String encodedPoints = await _travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _travelLocalDataSource.decodePolyline(encodedPoints);
        setState(() {
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

  void _showRouteDetails() {
    if (_startLocation != null && _endLocation != null) {
      double distance = _travelLocalDataSource.calculateDistance(
          _startLocation!, _endLocation!);
      print("Start: ${_startLocation!.longitude}, ${_startLocation!.latitude}");
      print("End: ${_endLocation!.longitude}, ${_endLocation!.latitude}");
      print("Distance: ${distance.toStringAsFixed(2)} km");

      final post = Travel(
        start_longitude: _startLocation!.longitude,
        start_latitude: _startLocation!.latitude,
        end_longitude: _endLocation!.longitude,
        end_latitude: _endLocation!.latitude,
        kilometers: distance.toStringAsFixed(2),
      );

      _travelGetx.poshTravel(CreateTravelEvent(post));

      Alert(
        context: context,
        type: AlertType.success,
        title: "Éxito",
        desc: "Te avisaremos cuando algún chofer acepte tu viaje",
        buttons: [
          DialogButton(
            child: Text(
              "OK",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () => Navigator.pop(context),
            width: 120,
          )
        ],
      ).show();
    }
  }

  Future<void> _searchPlace(String input) async {
    if (input.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    List<dynamic> predictions =
        await _travelLocalDataSource.getPlacePredictions(input);
    setState(() {
      _predictions = predictions;
    });
  }

  void _selectPlace(String placeId) async {
    await _travelLocalDataSource.getPlaceDetailsAndMove(placeId, (LatLng location) {
      _mapController.moveCamera(CameraUpdate.newLatLng(location));
    }, (LatLng location) {
      // Aquí añades los marcadores solo desde el buscador
      if (_markerCount == 0) { 
        _startLocation = location; // Marcador de inicio desde el buscador
        _markers.add(Marker(
          markerId: MarkerId('start'),
          position: location,
          infoWindow: InfoWindow(title: 'Inicio'),
        ));
      } else if (_markerCount == 1) {
        _endLocation = location; // Marcador de destino desde el buscador
        _markers.add(Marker(
          markerId: MarkerId('destination'),
          position: location,
          infoWindow: InfoWindow(title: 'Destino'),
        ));
        _traceRoute(); // Trazar la ruta cuando ya están ambos marcadores
      }
      _markerCount++;
    });

    setState(() {
      _predictions = [];
      _searchController.clear();
    });
  }

  void _resetMap() {
    setState(() {
      _markers.clear();
      _polylines.clear();
      _markerCount = 0;
      _startLocation = null;
      _endLocation = null;
      _buttonText = "Buscar";
    });
    _mapController.moveCamera(CameraUpdate.newLatLng(_center));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            polylines: _polylines,
            onTap: null,
          ),
          
          Positioned(
            top: 20.0,
            left: 10.0,
            right: 10.0,
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _resetMap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        textStyle: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.white),
                          SizedBox(width: 8.0),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                      decoration: InputDecoration(
                          labelText: _markerCount == 0
                              ? 'Buscar lugar de inicio'
                              : 'Buscar lugar destino',
                          labelStyle: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                          hintText: 'Escribe una dirección',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.blueAccent,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide:
                                BorderSide(color: Colors.blueAccent, width: 2.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8.0),
                    padding: EdgeInsets.all(10.0),
                    color: Colors.white,
                    child: Column(
                      children: _predictions.map((prediction) {
                        return ListTile(
                          title: Text(prediction['description']),
                          onTap: () {
                            _selectPlace(prediction['place_id']);
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 20.0,
            left: 10.0,
            right: 10.0,
            child: ElevatedButton(
              onPressed: _showRouteDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                textStyle: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, color: Colors.white),
                  SizedBox(width: 8.0),
                  Text(_buttonText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
