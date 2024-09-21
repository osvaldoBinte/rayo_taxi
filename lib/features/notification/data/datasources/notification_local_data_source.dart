import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rayo_taxi/features/notification/data/models/travel_alert_model.dart';
import 'package:rayo_taxi/features/notification/domain/entities/device.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import '../models/device_model.dart';

abstract class NotificationLocalDataSource {
  Future<void> updateIdDevice();
  Future<List<TravelAlertModel>> getNotification(bool connection);
    Future<List<TravelAlertModel>> getNotificationtravel(bool connection);

}

class NotificationLocalDataSourceImp implements NotificationLocalDataSource {
  final String _baseUrl =
      'https://developer.binteapi.com:3009/api/app_clients/users';

  late Device device;

  @override
  Future<void> updateIdDevice() async {
    String? savedToken = await _getToken();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('Device Token: $token');

    device = Device(id_device: token);

    var response = await http.put(
      Uri.parse('$_baseUrl/clients/device'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(DeviceModel.fromEntity(device).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el id device");
    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }

  Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
@override
Future<List<TravelAlertModel>> getNotification(bool connection) async {
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

  String? token = await _getToken();
  if (token == null) {
    throw Exception('Token no disponible');
  }

  if (connection) {
    try {
      var headers = {
        'x-token': token,
        'Content-Type': 'application/json',
      };

      print('Realizando la solicitud a $_baseUrl/auth/renew...');
      var response = await http.get(
        Uri.parse('$_baseUrl/auth/renew'),
        headers: headers,
      );

      print('Código de estado de la respuesta: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonResponse = convert.jsonDecode(response.body);
        print('Respuesta JSON: $jsonResponse');

        if (jsonResponse['data'] != null && jsonResponse['data']['travels'] != null) {
          var travels = jsonResponse['data']['travels'];
          
          print('Datos de viajes recibidos: $travels');

          // Cambiar aquí
          List<TravelAlertModel> travelsAlert = (travels as List)
              .map((travel) => TravelAlertModel.fromJson(travel))
              .toList();

          print('Viajes mapeados: $travelsAlert');
          sharedPreferences.setString('travelsAlert', jsonEncode(travelsAlert));
          print('Viajes guardados en SharedPreferences: ${travelsAlert.length}');

          return travelsAlert;
        } else {
          throw Exception('Estructura de respuesta inesperada');
        }
      } else {
        throw Exception('Error en la petición: ${response.statusCode}');
      }
    } catch (e) {
      print('Error capturado: $e');
      return _loadtravelsFromLocal(sharedPreferences);
    }
  } else {
    print('Conexión no disponible, cargando desde SharedPreferences...');
    return _loadtravelsFromLocal(sharedPreferences);
  }
}

Future<List<TravelAlertModel>> _loadtravelsFromLocal(
    SharedPreferences sharedPreferences) async {
  String clientsString = sharedPreferences.getString('travelsAlert') ?? "[]";
  print('Cargando viajes de SharedPreferences: $clientsString');
  
  List<dynamic> body = jsonDecode(clientsString);

  if (body.isNotEmpty) {
    return body
        .map<TravelAlertModel>((travels) => TravelAlertModel.fromJson(travels))
        .toList();
  } else {
    print(body);
    throw Exception('No hay viajes. sharedPreferences');
  }
}
Future<List<TravelAlertModel>> _loadtravelFromLocal(
    SharedPreferences sharedPreferences) async {
  String clientsString = sharedPreferences.getString('travelsAlert') ?? "[]";
  print('Cargando viajes de SharedPreferences: $clientsString');
  
  List<dynamic> body = jsonDecode(clientsString);

  if (body.isNotEmpty) {
    return body
        .map<TravelAlertModel>((travels) => TravelAlertModel.fromJson(travels))
        .toList();
  } else {
    print(body);
    throw Exception('No hay viajes. sharedPreferences');
  }
}

  @override
  Future<List<TravelAlertModel>> getNotificationtravel(bool connection) async {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

  String? token = await _getToken();
  if (token == null) {
    throw Exception('Token no disponible');
  }

  if (connection) {
    try {
      var headers = {
        'x-token': token,
        'Content-Type': 'application/json',
      };

      print('Realizando la solicitud a $_baseUrl/auth/renew...');
      var response = await http.get(
        Uri.parse('$_baseUrl/auth/renew'),
        headers: headers,
      );

      print('Código de estado de la respuesta: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonResponse = convert.jsonDecode(response.body);
        print('Respuesta JSON: $jsonResponse');

        if (jsonResponse['data'] != null && jsonResponse['data']['travels'] != null) {
          var travels = jsonResponse['data']['travels'];
          
          print('Datos de viajes recibidos: $travels');

          // Cambiar aquí
          List<TravelAlertModel> travelsAlert = (travels as List)
              .map((travel) => TravelAlertModel.fromJson(travel))
              .toList();

          print('Viajes mapeados: $travelsAlert');
          sharedPreferences.setString('travelsAlert', jsonEncode(travelsAlert));
          print('Viajes guardados en SharedPreferences: ${travelsAlert.length}');

          return travelsAlert;
        } else {
          throw Exception('Estructura de respuesta inesperada');
        }
      } else {
        throw Exception('Error en la petición: ${response.statusCode}');
      }
    } catch (e) {
      print('Error capturado: $e');
      return _loadtravelFromLocal(sharedPreferences);
    }
  } else {
    print('Conexión no disponible, cargando desde SharedPreferences...');
    return _loadtravelFromLocal(sharedPreferences);
  }

  }
}