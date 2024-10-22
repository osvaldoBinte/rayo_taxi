import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/presentation/page/mapa.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Importa el paquete geocoding

class DestinoPage extends StatefulWidget {
  @override
  _DestinoPageState createState() => _DestinoPageState();
}

class _DestinoPageState extends State<DestinoPage> {
  TextEditingController _destinoController = TextEditingController();
  List<dynamic> _predictions = [];
  TravelLocalDataSource _travelLocalDataSource = TravelLocalDataSourceImp();
  ValueNotifier<bool> _isButtonEnabled = ValueNotifier<bool>(false);

  String _currentAddress = '';
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    _getUserAddress();
  }

  @override
  void dispose() {
    _destinoController.dispose();
    _isButtonEnabled.dispose();
    super.dispose();
  }

  void _getUserAddress() async {
    try {
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

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentLatLng = LatLng(position.latitude, position.longitude);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        // Construye la dirección en formato legible incluyendo el código postal
        String address =
            '${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';
        print('direccion desde destino $address');

        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      print('Error al obtener la ubicación del usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener la ubicación')),
      );
    }
  }

  void _navigateToMapScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          endController: _destinoController,
          startAddress: _currentAddress, // Pasa la dirección del usuario
          startLatLng: _currentLatLng, // Pasa las coordenadas del usuario
        ),
      ),
    );
  }
void _searchPlace(String input) async {
  if (input.isEmpty) {
    setState(() {
      _predictions = [];
    });
    _isButtonEnabled.value = false;
    return;
  }

  _isButtonEnabled.value = true;

  try {
    List<dynamic> predictions = await _travelLocalDataSource.getPlacePredictions(input);
    print('Predicciones obtenidas en DestinoPage: ${predictions.length}'); // Debug
    setState(() {
      _predictions = predictions;
    });
  } catch (e) {
    print('Error al obtener predicciones en DestinoPage: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al obtener predicciones')),
    );
    setState(() {
      _predictions = [];
    });
    _isButtonEnabled.value = false;
  }
}


 void _selectPlace(String placeId, String description) async {
  try {
    await _travelLocalDataSource.getPlaceDetailsAndMove(
      placeId,
      (LatLng location) {
        // Implementa la lógica para mover la cámara al mapa si es necesario
        print('Mover a ubicación: $location'); // Debug
      },
      (LatLng location) {
        // Implementa la lógica para agregar un marcador si es necesario
        print('Agregar marcador en: $location'); // Debug
      },
    );

    setState(() {
      _destinoController.text = description;
      _predictions = [];
    });
    _isButtonEnabled.value = true;
  } catch (e) {
    print('Error al seleccionar lugar: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al seleccionar el lugar')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Introduce tu destino',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _destinoController,
                    onChanged: _searchPlace,
                    decoration: InputDecoration(
                      labelText: 'Agregar dirección destino',
                      labelStyle:
                          TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                            color: const Color.fromARGB(255, 0, 0, 0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            width: 2.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(height: 30),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isButtonEnabled,
                    builder: (context, isEnabled, child) {
                      return ElevatedButton(
                        onPressed: isEnabled ? _navigateToMapScreen : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEnabled
                              ? const Color.fromARGB(255, 8, 8, 8)
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 5,
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          'Ir a Mapa',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_predictions.isNotEmpty)
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
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      var prediction = _predictions[index];
                      return GestureDetector(
                        onTap: () {
                          _selectPlace(prediction['place_id'],
                              prediction['description']);
                        },
                        child: ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.8),
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
          ],
        ),
      ),
    );
  }
}
