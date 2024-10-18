import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/home_page.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/mapa_page.dart';
import 'package:rayo_taxi/main.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../connectivity_service.dart';
import '../../../notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';

class MapScreen extends StatefulWidget {
  final TextEditingController
      endController; // Recibe el controlador del destino
  final String startAddress; // Recibe la dirección de inicio
  final LatLng? startLatLng; // Recibe las coordenadas de inicio

  MapScreen({
    required this.endController,
    required this.startAddress,
    required this.startLatLng,
  }); // Constructor

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final TravelGetx _travelGetx = Get.find<TravelGetx>();
  final DeleteTravelGetx _deleteTravelGetx = Get.find<DeleteTravelGetx>();
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();
  final TravelsAlertGetx travelAlertGetx = Get.find<TravelsAlertGetx>();

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
  Completer<GoogleMapController> _controllerCompleter = Completer();

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _endController.text = widget.endController.text;
    _startController.text = widget.startAddress;
    print('mi direcion desde initState');

    print(_startController.text);
    print(widget.startAddress);
    // Si el texto de inicio no está vacío, busca y selecciona la ubicación
    if (_startController.text.isNotEmpty) {
      _searchAndSelectPlace(_startController.text, isStartPlace: true);
    }

    // Si el texto de destino no está vacío, busca y selecciona la ubicación
    if (_endController.text.isNotEmpty) {
      _searchAndSelectPlace(_endController.text, isStartPlace: false);
    }

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

    // Aseguramos que las listas de predicciones estén vacías al iniciar
    _startPredictions = [];
    _endPredictions = [];
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
    _controllerCompleter.complete(controller);

    if (widget.startLatLng != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(widget.startLatLng!, 15.0),
      );
      _addMarker(widget.startLatLng!, true);
    }
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

  void _searchAndSelectPlace(String placeName,
      {required bool isStartPlace}) async {
    if (placeName.isEmpty) return;

    // Obtiene las predicciones de lugares basadas en el nombre
    List<dynamic> predictions =
        await _travelLocalDataSource.getPlacePredictions(placeName);

    if (predictions.isNotEmpty) {
      String placeId = predictions.first['place_id'];
      // Selecciona el lugar y agrega el marcador en el mapa
      _selectPlace(placeId, isStartPlace);

      // Opcional: Actualiza el texto del controlador con la descripción del lugar
      if (isStartPlace) {
        _startController.text = predictions.first['description'];
      } else {
        _endController.text = predictions.first['description'];
      }
    } else {
      print('No se encontraron predicciones para $placeName');
    }
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
      double duration = _travelLocalDataSource.getDuration();

      print("Start: ${_startLocation!.longitude}, ${_startLocation!.latitude}");
      print("End: ${_endLocation!.longitude}, ${_endLocation!.latitude}");
      print("Distance: ${distance.toStringAsFixed(2)} km");

      final post = Travel(
        start_longitude: _startLocation!.longitude,
        start_latitude: _startLocation!.latitude,
        end_longitude: _endLocation!.longitude,
        end_latitude: _endLocation!.latitude,
        kilometers: distance.toStringAsFixed(2),
        duration: duration.toStringAsFixed(2),
      );

      await _travelGetx.poshTravel(CreateTravelEvent(post));
      await travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());

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
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.buttonColor,
                            foregroundColor:
                                Theme.of(context).colorScheme.buttontext),
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

    LatLng? locationBias;
    if (isStartPlace && widget.startLatLng != null) {
      locationBias = widget.startLatLng;
    }

    List<dynamic> predictions =
        await _travelLocalDataSource.getPlacePredictions(
      input,
      location: locationBias,
    );

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
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );
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

  void _getUserLocation() async {
    try {
      // Verifica y solicita permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permisos de ubicación denegados')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Permisos de ubicación denegados permanentemente')),
        );
        return;
      }

      // Obtiene la posición actual del usuario
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      // Realiza la geocodificación inversa para obtener la dirección
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      String address = '';
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        // Construye la dirección en formato legible
        address =
            '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        print('mi direccion desde mapa $address');
      }

      // Mueve el mapa a la ubicación del usuario
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation, 15.0),
      );

      // Actualiza el controlador de texto y agrega el marcador
      setState(() {
        _startController.text = address;
        _addMarker(userLocation, true); // Agrega el marcador de inicio
      });
    } catch (e) {
      print('Error al obtener la ubicación del usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener la ubicación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController currentController =
        _currentInputField == 'start' ? _startController : _endController;
    List<dynamic> currentPredictions =
        _currentInputField == 'start' ? _startPredictions : _endPredictions;

    // Verificamos si el campo actual tiene el foco
    bool isFieldFocused = _currentInputField == 'start'
        ? _startFocusNode.hasFocus
        : _endFocusNode.hasFocus;

    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar dirección'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Aquí navegas a la HomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
      ),
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
              top: 20.0,
              left: 10.0,
              right: 10.0,
              child: Container(
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            Icon(
                              Icons.circle,
                              color: Colors.black,
                              size: 12.0,
                            ),
                            Container(
                              height: 40.0,
                              width: 2.0,
                              color: Colors.grey,
                            ),
                            Icon(
                              Icons.square,
                              color: Colors.black,
                              size: 12.0,
                            ),
                          ],
                        ),
                        SizedBox(width: 10.0),
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: _startController,
                                focusNode: _startFocusNode,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Dirección de inicio',
                                  hintStyle: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _currentInputField = 'start';
                                  });
                                },
                              ),
                              Divider(
                                color: Colors.grey,
                                thickness: 1.0,
                              ),
                              TextField(
                                controller: _endController,
                                focusNode: _endFocusNode,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '¿A dónde vas?',
                                  hintStyle: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _currentInputField = 'end';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 80.0,
              left: 20.0,
              right: 20.0,
              child: ElevatedButton(
                onPressed: _showRouteDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.buttonColormap,
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
                      color: Colors.white, // Color del ícono
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      _buttonText,
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white, // Color del texto
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isFieldFocused &&
                currentController.text.isNotEmpty &&
                currentPredictions.isNotEmpty)
              Positioned(
                top: 140.0,
                left: 20.0,
                right: 20.0,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  margin: EdgeInsets.only(top: 8.0),
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
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
                          _selectPlace(prediction['place_id'], isStartPlace);

                          if (isStartPlace) {
                            _startController.text = prediction['description'];
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
                                .primary
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
              ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              right: 25.0,
              child: FloatingActionButton(
                onPressed: _getUserLocation,
                child: Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
