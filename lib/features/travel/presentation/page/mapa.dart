import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/mapa_page.dart';
import 'package:rayo_taxi/main.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../connectivity_service.dart';
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
  final DeleteTravelGetx _deleteTravelGetx = Get.find<DeleteTravelGetx>();
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();

  Set<gmaps.Marker> _markers = {};
  Set<Polyline> _polylines = {};
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
  String _currentInputField = 'start';

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

  void _showRouteDetails() async {
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

      await _travelGetx.poshTravel(CreateTravelEvent(post));

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
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          int? savedTravelId = await _getSavedTravelId();

                          if (savedTravelId != null) {
                            print('ID del viaje a cancelar: $savedTravelId');

                            await _deleteTravelGetx.deleteTravel(
                                DeleteTravelEvent(savedTravelId.toString()));

                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'No se encontró un ID de viaje válido')),
                            );
                          }
                        },
                        child: Text('Cancelar viaje'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, ingresa la dirección de inicio y destino.'),
          duration: Duration(seconds: 3),
        ),
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
        _addMarker(location, isStartPlace);
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
    TextEditingController currentController =
        _currentInputField == 'start' ? _startController : _endController;
    List<dynamic> currentPredictions =
        _currentInputField == 'start' ? _startPredictions : _endPredictions;

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
            Positioned(
              bottom: 80.0,
              left: 20.0,
              right: 20.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.buttonColormap,
                      Theme.of(context).colorScheme.buttonColormap2
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15.0,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _showRouteDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 18.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions,
                        color: Theme.of(context).colorScheme.iconwhite,
                      ),
                      SizedBox(width: 10.0),
                      Text(
                        _buttonText,
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(fontSize: 18.0),
                      ),
                    ],
                  ),
                ),
              ),
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
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                      hintText: 'Escribe una dirección de inicio',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.blueAccent,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 14.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  TextField(
                    focusNode: _endFocusNode,
                    controller: _endController,
                    decoration: InputDecoration(
                      labelText: 'Buscar lugar de destino',
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                      hintText: 'Escribe una dirección de destino',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.blueAccent,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 14.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (currentController.text.isNotEmpty &&
                      currentPredictions.isNotEmpty)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      margin:
                          EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                      padding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 10.0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        itemCount: currentPredictions.length,
                        itemBuilder: (context, index) {
                          var prediction = currentPredictions[index];
                          return GestureDetector(
                            onTap: () {
                              bool isStartPlace = _currentInputField == 'start';
                              _selectPlace(
                                  prediction['place_id'], isStartPlace);

                              if (isStartPlace) {
                                _startController.text =
                                    prediction['description'];
                              } else {
                                _endController.text = prediction['description'];
                              }

                              FocusScope.of(context).unfocus();
                            },
                            child: ListTile(
                              leading: Icon(
                                Icons.location_on,
                                color: Theme.of(context)
                                    .colorScheme
                                    .blueAccent
                                    .withOpacity(0.8),
                              ),
                              title: Text(
                                prediction['description'],
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}