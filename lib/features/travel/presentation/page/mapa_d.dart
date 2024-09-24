import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

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
  Set<gmaps.Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int _markerCount = 0;
  LatLng? _startLocation;
  LatLng? _endLocation;
  LatLng _center = const LatLng(20.676666666667, -103.39182);
  String _buttonText = "Buscar conductor";
  List<dynamic> _startPredictions = [];
  List<dynamic> _endPredictions = [];
  TextEditingController _startController = TextEditingController();
  TextEditingController _endController = TextEditingController();
  TravelLocalDataSource _travelLocalDataSource = TravelLocalDataSourceImp();

  late ConnectivityService _connectivityService;

  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _endFocusNode = FocusNode();
  String _currentInputField = 'start'; // 'start' o 'end'

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();

    _startController.addListener(() {
      if (_currentInputField == 'start') {
        _searchPlace(_startController.text, isStartPlace: true);
      }
    });

    _endController.addListener(() {
      if (_currentInputField == 'end') {
        _searchPlace(_endController.text, isStartPlace: false);
      }
    });

    // Escuchar cambios en la conectividad
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

    // Escuchar cambios de foco
    _startFocusNode.addListener(() {
      if (_startFocusNode.hasFocus) {
        setState(() {
          _currentInputField = 'start';
        });
      }
    });

    _endFocusNode.addListener(() {
      if (_endFocusNode.hasFocus) {
        setState(() {
          _currentInputField = 'end';
        });
      }
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _startFocusNode.dispose();
    _endFocusNode.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addMarker(LatLng latLng) {
    setState(() {
      if (_markerCount == 0) {
        // Marcador de inicio
        _markers.add(
          gmaps.Marker(
            markerId: MarkerId('start'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Inicio'),
          ),
        );
        _startLocation = latLng;
      } else if (_markerCount == 1) {
        // Marcador de destino
        _markers.add(
          gmaps.Marker(
            markerId: MarkerId('destination'),
            position: latLng,
            infoWindow: InfoWindow(title: 'Destino'),
          ),
        );
        _endLocation = latLng;
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

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return FractionallySizedBox(
            heightFactor: 0.75,
            widthFactor: 1.0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        height: 300,
                        child: Lottie.network(
                          'https://lottie.host/e44ab786-30a1-48ee-96eb-bb2e002f3ae8/NtzqQeAN8j.json',
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Buscando chofer...',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _searchPlace(String input, {required bool isStartPlace}) async {
    if (input.isEmpty) {
      setState(() {
        if (isStartPlace) {
          _startPredictions = [];
        } else {
          _endPredictions = [];
        }
      });
      return;
    }

    List<dynamic> predictions =
        await _travelLocalDataSource.getPlacePredictions(input);
    setState(() {
      if (isStartPlace) {
        _startPredictions = predictions;
      } else {
        _endPredictions = predictions;
      }
    });
  }

  void _selectPlace(String placeId, bool isStartPlace) async {
    await _travelLocalDataSource.getPlaceDetailsAndMove(
      placeId,
      (LatLng location) {
        _mapController.moveCamera(CameraUpdate.newLatLng(location));
      },
      (LatLng location) {
        _addMarker(location);
      },
    );

    setState(() {
      if (isStartPlace) {
        _startPredictions = [];
      } else {
        _endPredictions = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> currentPredictions =
        _currentInputField == 'start' ? _startPredictions : _endPredictions;

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
          ),
          Positioned(
            top: 20.0,
            left: 10.0,
            right: 10.0,
            child: Column(
              children: [
                TextField(
                  focusNode: _startFocusNode,
                  controller: _startController,
                  decoration: InputDecoration(
                    labelText: 'Buscar lugar de inicio',
                    labelStyle: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    hintText: 'Escribe una dirección de inicio',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.blueAccent,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (currentPredictions.isNotEmpty && _currentInputField == 'start')
                  _buildPredictionList(currentPredictions, true),
                SizedBox(height: 10.0),
                TextField(
                  focusNode: _endFocusNode,
                  controller: _endController,
                  decoration: InputDecoration(
                    labelText: 'Buscar lugar de destino',
                    labelStyle: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    hintText: 'Escribe una dirección de destino',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.blueAccent,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (currentPredictions.isNotEmpty && _currentInputField == 'end')
                  _buildPredictionList(currentPredictions, false),
                SizedBox(height: 10.0),
              ],
            ),
          ),
          Positioned(
            bottom: 16.0,
            left: 10.0,
            right: 10.0,
            child: ElevatedButton(
              onPressed: _showRouteDetails,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16.0),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                _buttonText,
                style: TextStyle(fontSize: 18.0, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }Widget _buildPredictionList(List<dynamic> predictions, bool isStartPlace) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
    padding: EdgeInsets.all(8.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.3),
          spreadRadius: 3,
          blurRadius: 7,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: ListView.builder(
        shrinkWrap: true, // Para que se ajuste al contenido
        itemCount: predictions.length,
        itemBuilder: (context, index) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _selectPlace(predictions[index]['place_id'], isStartPlace);
              },
              splashColor: Colors.blueAccent.withOpacity(0.2), // Efecto al presionar
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: index == predictions.length - 1
                          ? Colors.transparent
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.place,
                      color: Colors.blueAccent.withOpacity(0.8),
                    ),
                    SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        predictions[index]['description'],
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
}