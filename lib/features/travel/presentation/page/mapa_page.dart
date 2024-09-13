import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  final LatLng _center = const LatLng(20.66682, -103.39182);
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _placePredictions = [];
  final String _apiKey = 'AIzaSyDUVS-wh25ShrtIHnuXW0J8MuBRz9KC7ak';

  Set<Marker> _markers = {};
  bool _canAddMarker = false;
  bool _isAddingStart = true;
  String _buttonText = "Agregar dirección de inicio";

  LatLng? _startLocation;
  LatLng? _endLocation;
  Set<Polyline> _polylines = {};

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _moveToLocation(double lat, double lng) {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 14.0,
        ),
      ),
    );
  }

  void _addMarker(LatLng position) {
    if (_canAddMarker) {
      setState(() {
        if (_isAddingStart) {
          _startLocation = position;
          _markers.add(
            Marker(
              markerId: MarkerId("start"),
              position: position,
              infoWindow: InfoWindow(
                title: 'Dirección de inicio',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
          _buttonText = "Agregar dirección de destino";
        } else {
          _endLocation = position;
          _markers.add(
            Marker(
              markerId: MarkerId("destination"),
              position: position,
              infoWindow: InfoWindow(
                title: 'Dirección de destino',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
          _buttonText = "Dirección completada";

          // Obtener la ruta
          _getRoute();
        }

        _canAddMarker = false;
        _isAddingStart = !_isAddingStart;
      });
    }
  }

  Future<void> _getRoute() async {
    if (_startLocation != null && _endLocation != null) {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${_startLocation!.latitude},${_startLocation!.longitude}&destination=${_endLocation!.latitude},${_endLocation!.longitude}&key=$_apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final points = result['routes'][0]['overview_polyline']['points'];
        _createPolylines(points);
      } else {
        throw Exception('Error al obtener la ruta');
      }
    }
  }

  void _createPolylines(String encodedPoints) {
    List<LatLng> polylineCoordinates = _decodePolyline(encodedPoints);

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: polylineCoordinates,
        ),
      );
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; 

    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLon = _degreesToRadians(end.longitude - start.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _getPlacePredictions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final predictions = json.decode(response.body)['predictions'];
      setState(() {
        _placePredictions = predictions;
      });
    } else {
      throw Exception('Error obteniendo predicciones');
    }
  }

  Future<void> _getPlaceDetailsAndMove(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final result = json.decode(response.body)['result'];
      final location = result['geometry']['location'];
      final LatLng latLng = LatLng(location['lat'], location['lng']);
      _moveToLocation(latLng.latitude, latLng.longitude);
      _addMarker(latLng);
    } else {
      throw Exception('Error obteniendo detalles del lugar');
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }
    void _clearRouteAndMarkers() {
    setState(() {
      _markers.clear();
      _polylines.clear();
      _startLocation = null;
      _endLocation = null;
      _buttonText = "Agregar dirección de inicio";
      _canAddMarker = false;
      _isAddingStart = true;
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Google Maps'),
      backgroundColor: Color.fromARGB(255, 238, 230, 83),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  _getPlacePredictions(value);
                },
                decoration: InputDecoration(
                  hintText: 'Buscar ubicación',
                  suffixIcon: Icon(Icons.search),
                ),
              ),
              if (_searchFocusNode.hasFocus && _placePredictions.isNotEmpty)
                SingleChildScrollView(
                  child: Container(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _placePredictions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(Icons.place, color: Colors.red),
                          title: Text(_placePredictions[index]['description']),
                          onTap: () {
                            _getPlaceDetailsAndMove(_placePredictions[index]['place_id']);
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                            setState(() {
                              _placePredictions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            polylines: _polylines,
            onTap: (position) {
              _addMarker(position);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // Alinea los botones en el centro
          children: [
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _clearRouteAndMarkers, // Limpia las rutas y marcadores
            ),
            ElevatedButton(
              onPressed: () {
                if (_buttonText == "Dirección completada") {
                  if (_startLocation != null && _endLocation != null) {
                    double distance = _calculateDistance(_startLocation!, _endLocation!);
                    print("start_longitude: ${_startLocation!.longitude}, start_latitude: ${_startLocation!.latitude}");
                    print("end_longitude: ${_endLocation!.longitude}, end_latitude: ${_endLocation!.latitude}");
                    print("kilometers: $distance");
                  } else {
                    print("Por favor selecciona las ubicaciones de inicio y destino");
                  }
                } else {
                  setState(() {
                    _canAddMarker = true;
                  });
                }
              },
              child: Text(_buttonText),
            ),
          ],
        ),
      ],
    ),
  );
}

}
