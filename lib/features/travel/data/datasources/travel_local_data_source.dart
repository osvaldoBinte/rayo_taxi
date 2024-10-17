import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rayo_taxi/features/travel/domain/entities/device.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import '../models/device_model.dart';
import '../models/travel_alert_model.dart';

abstract class TravelLocalDataSource {
  Future<void> updateIdDevice();

  Future<void> acceptedTravel(int? id_travel);
  Future<void> startTravel(int? id_travel);
  Future<void> endTravel(int? id_travel);

  Future<List<TravelAlertModel>> getTravel(bool connection);

  Future<List<TravelAlertModel>> getalltravel(bool connection);

  Future<List<TravelAlertModel>> getbyIdtravelid(
      int? idTravel, bool connection);
  Future<String?> fetchDeviceId();
}

class TravelLocalDataSourceImp implements TravelLocalDataSource {
  final String _baseUrl =
      'https://developer.binteapi.com:3009/api/app_drivers/users';

  final String _baseUrl2 =
      'https://developer.binteapi.com:3009/api/app_drivers/travels';

  late Device device;

  @override
  Future<void> updateIdDevice() async {
    String? savedToken = await _getToken();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('Device Token: $token');

    device = Device(id_device: token);

    var response = await http.put(
      Uri.parse('$_baseUrl/drivers/device'),
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
  Future<List<TravelAlertModel>> getTravel(bool connection) async {
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

          if (jsonResponse['data'] != null &&
              jsonResponse['data']['current_travel'] != null) {
            var travel = jsonResponse['data']['current_travel'];

            print('hola soy current_travel: $travel');

            // Cambiar aquí
            TravelAlertModel travelAlert = TravelAlertModel.fromJson(travel);

            print('Viaje mapeado: $travelAlert');
            sharedPreferences.setString(
                'current_travel', jsonEncode(travelAlert.toJson()));

            // print('Viaje guardado en SharedPreferences');
            //sharedPreferences.setInt('current_travel_id', travelAlert.id);

            print(
                'ID del viaje guardado en SharedPreferences: ${travelAlert.id}');
            print("ultimo viaje 200");
            return [travelAlert];
          } else {
            throw Exception('Estructura de respuesta inesperada  ultimo viaje');
          }
        } else {
          throw Exception(
              'Error en la petición de ultimo viaje: ${response.statusCode}');
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

  Future<List<TravelAlertModel>> _loadtravelsFromLocal(
      SharedPreferences sharedPreferences) async {
    String clientsString = sharedPreferences.getString('travelsAlert') ?? "[]";
    print('Cargando viajes de SharedPreferences: $clientsString');

    List<dynamic> body = jsonDecode(clientsString);

    if (body.isNotEmpty) {
      return body
          .map<TravelAlertModel>(
              (travels) => TravelAlertModel.fromJson(travels))
          .toList();
    } else {
      print(body);
      throw Exception('No hay viajes. sharedPreferences');
    }
  }

  Future<List<TravelAlertModel>> _loadtravelFromLocal(
      SharedPreferences sharedPreferences) async {
    String clientsString =
        sharedPreferences.getString('current_travel') ?? "[]";
    print('Cargando viajes de SharedPreferences: $clientsString');

    List<dynamic> body = jsonDecode(clientsString);

    if (body.isNotEmpty) {
      return body
          .map<TravelAlertModel>(
              (travels) => TravelAlertModel.fromJson(travels))
          .toList();
    } else {
      print(body);
      throw Exception('No hay viajes. sharedPreferences');
    }
  }

  @override
  Future<List<TravelAlertModel>> getalltravel(bool connection) async {
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

          if (jsonResponse['data'] != null &&
              jsonResponse['data']['travels'] != null) {
            var travels = jsonResponse['data']['travels'];

            print('Datos de viajes recibidos: $travels');

            List<TravelAlertModel> travelsAlert = (travels as List)
                .map((travel) => TravelAlertModel.fromJson(travel))
                .toList();

            print('Viajes mapeados: $travelsAlert');
            sharedPreferences.setString(
                'travelsAlert', jsonEncode(travelsAlert));
            print(
                'Viajes guardados en SharedPreferences: ${travelsAlert.length}');

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

  @override
  Future<List<TravelAlertModel>> getbyIdtravelid(
      int? idTravel, bool connection) async {
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

        print('Realizando la solicitud a $_baseUrl/travels/$idTravel');
        var response = await http.get(
          Uri.parse(
              'https://developer.binteapi.com:3009/api/app_drivers/travels/travels/$idTravel'), // Cambié la URL para incluir el idTravel
          headers: headers,
        );

        print('Código de estado de la respuesta: ${response.statusCode}');
        if (response.statusCode == 200) {
          final jsonResponse = convert.jsonDecode(response.body);
          print('Respuesta JSON: $jsonResponse');

          if (jsonResponse['data'] != null) {
            var travelData = jsonResponse['data'];

            print('Datos de viaje recibido: $travelData');

            TravelAlertModel travelAlertbyid =
                TravelAlertModel.fromJson(travelData);

            print('Viaje mapeado: $travelAlertbyid');
            // Guardar un solo objeto, no como lista
            sharedPreferences.setString(
              'getalltravelid',
              jsonEncode(travelAlertbyid.toJson()),
            );

            print('Viaje guardado en SharedPreferences: getalltravelid');
            return [travelAlertbyid];
          } else {
            throw Exception('Estructura de respuesta inesperada');
          }
        } else {
          throw Exception('Error en la petición: ${response.body}');
        }
      } catch (e) {
        print('Error capturado: $e');
        return _loadtravelbyIDFromLocal(sharedPreferences);
      }
    } else {
      print('Conexión no disponible, cargando desde SharedPreferences...');
      return _loadtravelbyIDFromLocal(sharedPreferences);
    }
  }

  Future<List<TravelAlertModel>> _loadtravelbyIDFromLocal(
      SharedPreferences sharedPreferences) async {
    String travelString = sharedPreferences.getString('getalltravelid') ?? "";

    if (travelString.isNotEmpty) {
      print('Cargando viaje de SharedPreferences: $travelString');

      // Parsear como un solo objeto, no una lista
      Map<String, dynamic> travelMap = convert.jsonDecode(travelString);
      TravelAlertModel travelAlert = TravelAlertModel.fromJson(travelMap);

      return [travelAlert]; // Retornar como lista
    } else {
      print('No hay viajes en SharedPreferences');
      throw Exception('No hay viajes en SharedPreferences');
    }
  }

  @override
  Future<String?> fetchDeviceId() async {
    try {
      final String url = '$_baseUrl/auth/renew';
      print('Realizando la solicitud a $url...');

      String? token = await _getToken();
      if (token == null) {
        throw Exception('Token no disponible');
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-token': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Decodificar la respuesta en JSON
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Extraer el `id_device` del JSON
        String? idDevice = jsonResponse['data']['id_device'];
        print('ID del dispositivo obtenido: $idDevice');

        return idDevice; // Retornar el id_device
      } else {
        // Manejo de errores cuando el estado no es 200
        print('Error en la solicitud: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Manejo de excepciones
      print('Error obteniendo el id_device: $e');
      return null;
    }
  }

  @override
  Future<void> acceptedTravel(int? id_travel) async {
    String? savedToken = await _getToken();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('Device Token: $token');

    device = Device(id_device: token);

    var response = await http.put(
      Uri.parse('$_baseUrl2/travels/accepted/$id_travel'),
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
  
  @override
  Future<void> endTravel(int? id_travel) async {
    String? savedToken = await _getToken();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('Device Token: $token');

    device = Device(id_device: token);

    var response = await http.put(
      Uri.parse('$_baseUrl2/travels/end/$id_travel'),
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
  
  @override
  Future<void> startTravel(int? id_travel) async{
   String? savedToken = await _getToken();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('Device Token: $token');

    device = Device(id_device: token);

    var response = await http.put(
      Uri.parse('$_baseUrl2/travels/start/$id_travel'),
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
}
