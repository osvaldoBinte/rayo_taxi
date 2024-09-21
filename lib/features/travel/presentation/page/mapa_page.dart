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
  LatLng? _startLocation;
  LatLng? _endLocation;
  LatLng _center = const LatLng(20.676666666667, -103.39182);
  String _buttonText = "Buscar conductor";
  List<dynamic> _predictionsStart = [];
  List<dynamic> _predictionsEnd = [];
  TextEditingController _startController = TextEditingController();
  TextEditingController _endController = TextEditingController();
  TravelLocalDataSource _travelLocalDataSource = TravelLocalDataSourceImp();
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();

    _startController.addListener(() {
      _searchPlace(_startController.text, true);
    });

    _endController.addListener(() {
      _searchPlace(_endController.text, false);
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
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _addMarker(LatLng latLng, bool isStart) {
    setState(() {
      if (isStart) {
        _startLocation = latLng;
        _markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('start'),
            position: latLng,
            infoWindow: gmaps.InfoWindow(title: 'Inicio'),
          ),
        );
      } else {
        _endLocation = latLng;
        _markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('destination'),
            position: latLng,
            infoWindow: gmaps.InfoWindow(title: 'Destino'),
          ),
        );
      }

      if (_startLocation != null && _endLocation != null) {
        _traceRoute();
      }
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 500,
                      child: Lottie.network(
                        'https://lottie.host/e44ab786-30a1-48ee-96eb-bb2e002f3ae8/NtzqQeAN8j.json', // Cargar animación desde la URL
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Buscando chofer',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _searchPlace(String input, bool isStart) async {
    if (input.isEmpty) {
      setState(() {
        if (isStart) {
          _predictionsStart = [];
        } else {
          _predictionsEnd = [];
        }
      });
      return;
    }

    List<dynamic> predictions =
        await _travelLocalDataSource.getPlacePredictions(input);
    setState(() {
      if (isStart) {
        _predictionsStart = predictions;
      } else {
        _predictionsEnd = predictions;
      }
    });
  }

  void _selectPlace(String placeId, bool isStart) async {
    await _travelLocalDataSource.getPlaceDetailsAndMove(placeId,
        (LatLng location) {
      _mapController.moveCamera(CameraUpdate.newLatLng(location));
      _addMarker(location, isStart);
    }, (LatLng location) {});

    setState(() {
      if (isStart) {
        _startController.text = _predictionsStart.isNotEmpty
            ? _predictionsStart.first['description']
            : '';
        _predictionsStart = [];
      } else {
        _endController.text = _predictionsEnd.isNotEmpty
            ? _predictionsEnd.first['description']
            : '';
        _predictionsEnd = [];
      }
    });
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
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            _openAddTripModal(context);
          },
          label: Text('Agregar viaje'),
          icon: Icon(Icons.add),
          backgroundColor: Colors.blueAccent,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerFloat, // Ubica el botón en el centro inferior
    );
  }

  void _openAddTripModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // Ajusta el espacio cuando el teclado aparece
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _startController,
                labelText: 'Lugar de inicio',
                hintText: 'Escribe una dirección de inicio',
              ),
              _buildPredictionList(_predictionsStart, true),
              SizedBox(height: 20),
              _buildTextField(
                controller: _endController,
                labelText: 'Lugar de destino',
                hintText: 'Escribe una dirección de destino',
              ),
              _buildPredictionList(_predictionsEnd, false),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showRouteDetails();
                },
                icon: Icon(Icons.search),
                label: Text('Buscar conductor'),
              ),
            ],
          ),
        ),
      );
    },
  );
}


  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[600],
        ),
        prefixIcon: Icon(
          Icons.location_on,
          color: Colors.blueAccent,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
        ),
      ),
    );
  }

  Widget _buildPredictionList(List<dynamic> predictions, bool isStart) {
    if (predictions.isEmpty) return SizedBox();
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(top: 8.0),
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 250, 246, 246),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListView(
          shrinkWrap: true,
          children: predictions.map((prediction) {
            return ListTile(
              title: Text(prediction['description']),
              onTap: () => _selectPlace(prediction['place_id'], isStart),
            );
          }).toList(),
        ),
      ),
    );
  }
}
