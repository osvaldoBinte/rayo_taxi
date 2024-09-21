import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:rayo_taxi/features/travel/data/models/travel_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class TravelLocalDataSource {
  Future<void> poshTravel(Travel travel);
  Future<void> getRoute(LatLng startLocation, LatLng endLocation);
  List<LatLng> decodePolyline(String encoded);
  double calculateDistance(LatLng start, LatLng end);
  double degreesToRadians(double degrees);
  Future<List<dynamic>> getPlacePredictions(String input);
  Future<void> getPlaceDetailsAndMove(String placeId, Function(LatLng) moveToLocation, Function(LatLng) addMarker);
  Future<String> getEncodedPoints();
  Future<Map<String, dynamic>> getPlaceDetails(String placeId); // Nueva función
}

class TravelLocalDataSourceImp implements TravelLocalDataSource {
  final String _apiKey = 'AIzaSyDUVS-wh25ShrtIHnuXW0J8MuBRz9KC7ak';
  String? _encodedPoints;
  final String _baseUrl =
      'https://developer.binteapi.com:3009/api/app_clients/travels';

  @override
  Future<void> getRoute(LatLng startLocation, LatLng endLocation) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${startLocation.latitude},${startLocation.longitude}&destination=${endLocation.latitude},${endLocation.longitude}&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      _encodedPoints = result['routes'][0]['overview_polyline']['points'];
    } else {
      throw Exception('Error al obtener la ruta');
    }
  }

  @override
  List<LatLng> decodePolyline(String encoded) {
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

  @override
  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371;

    double dLat = degreesToRadians(end.latitude - start.latitude);
    double dLon = degreesToRadians(end.longitude - start.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(start.latitude)) *
            cos(degreesToRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  double degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  @override
  Future<List<dynamic>> getPlacePredictions(String input) async {
    if (input.isEmpty) return [];

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final predictions = json.decode(response.body)['predictions'];
      return predictions;
    } else {
      throw Exception('Error obteniendo predicciones');
    }
  }

  @override
  Future<void> getPlaceDetailsAndMove(String placeId,
      Function(LatLng) moveToLocation, Function(LatLng) addMarker) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final result = json.decode(response.body)['result'];
      final location = result['geometry']['location'];
      final LatLng latLng = LatLng(location['lat'], location['lng']);
      moveToLocation(latLng);
      addMarker(latLng);
    } else {
      throw Exception('Error obteniendo detalles del lugar');
    }
  }

  @override
  Future<String> getEncodedPoints() async {
    if (_encodedPoints != null) {
      return _encodedPoints!;
    } else {
      throw Exception('Encoded points no disponibles');
    }
  }

@override
Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
  final String url =
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final result = json.decode(response.body)['result'];
     return {
      'name': result['name'],  
      'lat': result['geometry']['location']['lat'],
      'lng': result['geometry']['location']['lng'],
    };
  } else {
    throw Exception('Error obteniendo detalles del lugar');
  }
}


  Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Future<void> poshTravel(Travel travel) async {
    String? savedToken = await _getToken();

    var response = await http.post(
      Uri.parse('$_baseUrl/travels'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(TravelModel.fromEntity(travel).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }
}
