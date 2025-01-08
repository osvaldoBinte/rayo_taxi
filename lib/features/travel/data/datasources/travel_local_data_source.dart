import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:rayo_taxi/features/travel/data/models/Travelwithtariff/Travelwithtariff_model.dart';
import 'package:rayo_taxi/features/travel/data/models/Travelwithtariff/confirmar_tariff_model.dart';
import 'package:rayo_taxi/features/travel/data/models/getcosttravel/getcosttravel_model.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/deviceEntitie/device.dart';
import 'package:rayo_taxi/features/travel/domain/entities/getcosttraveEntitie/getcosttravel_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/confirmar_tariff_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travelwithtariffEntitie/travelwithtariff_entitie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import '../models/device/device_model.dart';
import 'dart:convert';

abstract class NotificationLocalDataSource {
  Future<void> updateIdDevice();
  Future<List<TravelAlertModel>> getNotification(bool connection);
  Future<List<TravelAlertModel>> current_travel();
  Future<String?> fetchDeviceId();
  Future<List<TravelAlertModel>> getbyIdtravelid(
      int? idTravel, bool connection);
  Future<void> confirmTravelWithTariff(ConfirmarTariffEntitie confirmarTariffEntitie);
  Future<void> rejectTravelOffer(TravelwithtariffEntitie travelwithtariffEntitie);
  Future<void> removedataaccount();
  Future<void> offerNegotiation(TravelwithtariffEntitie travelwithtariffEntitie);
   Future<GetcosttravelEntitie> getcosttravel(GetcosttravelEntitie getcosttravelEntitie);
}

class NotificationLocalDataSourceImp implements NotificationLocalDataSource {
    String _baseUrl = AppConstants.serverBase;

  late Device device;

  @override
  Future<void> updateIdDevice() async {
    String? savedToken = await AuthService().getToken();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print('Device Token: $token');

    device = Device(id_device: token);

    var response = await http.put(
      Uri.parse('$_baseUrl/app_clients/users/clients/device'),
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
  Future<List<TravelAlertModel>> getNotification(bool connection) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String? token = await AuthService().getToken();
    if (token == null) {
      throw Exception('Token no disponible');
    }

    if (connection) {
      try {
        var headers = {
          'x-token': token,
          'Content-Type': 'application/json',
        };

        var response = await http.get(
          Uri.parse('$_baseUrl/app_clients/users/auth/renew'),
          headers: headers,
        );

        print(
            'Código de estado de la respuesta de travel auth/renew : ${response.statusCode}');
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

            print('Viajes mapeados de travel: $travelsAlert');
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
  Future<List<TravelAlertModel>> current_travel() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String? token =  await AuthService().getToken();
    if (token == null) {
      throw Exception('Token no disponible');
    }
  //if (connection) {
      try {
        var headers = {
          'x-token': token,
          'Content-Type': 'application/json',
        };

        var response = await http.get(
          Uri.parse('$_baseUrl/app_clients/users/auth/renew'),
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

            TravelAlertModel travelAlert = TravelAlertModel.fromJson(travel);

            print('Viaje mapeado: $travelAlert');
            sharedPreferences.setString(
                'current_travel', jsonEncode(travelAlert.toJson()));

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
  //}else {print('Conexión no disponible, cargando desde SharedPreferences...');
    //  return _loadtravelFromLocal(sharedPreferences);
    //}
  }

@override
Future<String?> fetchDeviceId() async {
  try {
    final String url = '$_baseUrl/app_clients/users/auth/renew';
    print('Realizando la solicitud a $url...');

    String? token =  await AuthService().getToken();
    if (token == null) {
      throw Exception('Token no disponible');
    }

    print('Token obtenido: $token'); 
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'x-token': 'Bearer $token', 
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      String? idDevice = jsonResponse['data']['id_device'];
      print('ID del dispositivo obtenido: $idDevice');

      return idDevice;
    } else {
      print('Error en la solicitud id_device: ${response.statusCode}');
      print('Respuesta del servidor: ${response.body}'); 
      return null;
    }
  } catch (e) {
    print('Error obteniendo el id_device: $e');
    return null;
  }
}


  @override
  Future<List<TravelAlertModel>> getbyIdtravelid(
      int? idTravel, bool connection) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String? token =  await AuthService().getToken();
    if (token == null) {
      throw Exception('Token no disponible');
    }

    if (connection) {
      try {
        var headers = {
          'x-token': token,
          'Content-Type': 'application/json',
        };
        final String url = '$_baseUrl/app_clients/travels/travels/$idTravel';

        print('Realizando la solicitud a $url');
        var response = await http.get(
          Uri.parse(url),
          headers: headers,
        );

        print('Código de estado de la respuesta: ${response.statusCode}');
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          print('Respuesta JSON completa: $jsonResponse');

          if (jsonResponse['data'] != null) {
            var travelData = jsonResponse['data'];


            print('Datos de viaje recibido: $travelData');
            print('Conductores recibidos: ${travelData['drivers']}');

            TravelAlertModel travelAlertbyid =
                TravelAlertModel.fromJson(travelData);



            print('El id_status es: ${travelAlertbyid.id_status}');
            SharedPreferences sharedPreferences =
                await SharedPreferences.getInstance();
            int id_statuss = jsonResponse['data']['id_status'];

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setInt('id_status', id_statuss);
            //  int? idStatus = sharedPreferences.getInt('id_status',id_statuss);

            print('El id_status guardado es: $id_statuss');

            print('Viaje mapeado: $travelAlertbyid');
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

      Map<String, dynamic> travelMap = convert.jsonDecode(travelString);
      TravelAlertModel travelAlert = TravelAlertModel.fromJson(travelMap);

      return [travelAlert]; 
    } else {
      print('No hay viajes en SharedPreferences');
      throw Exception('No hay viajes en SharedPreferences');
    }
  }

  
@override
Future<void> confirmTravelWithTariff(ConfirmarTariffEntitie confirmarTariffEntitie) async {
  try {
    String? savedToken = await AuthService().getToken();

    if (savedToken == null || savedToken.isEmpty) {
      throw Exception('Token de autenticación no disponible.');
    }

    final uri = Uri.parse('$_baseUrl/app_clients/travels/travels/confirmTravelWithTariff');

    final bodyJson = ConfirmarTariffModel.fromEntity(confirmarTariffEntitie).toJson();

    print('--- ConfirmTravelWithTariff Request ---');
    print('URL: ${uri.toString()}');
    print('Headers: ${{
      'Content-Type': 'application/json',
      'x-token': savedToken,
    }}');
    print('Body: ${jsonEncode(bodyJson)}');
    print('--------------------------------------');

    var response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken,
      },
      body: jsonEncode(bodyJson),
    );

    print('--- ConfirmTravelWithTariff Response ---');
    print('Status Code: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');
    print('---------------------------------------');

    if (response.headers['content-type']?.contains('application/json') ?? false) {
      dynamic body = jsonDecode(response.body);
      print('Parsed JSON Body: $body');

      if (response.statusCode == 200) {
        String message = body['message'].toString();
        print("Confirmación exitosa: $message");
      } else {
        String message = body['message'].toString();
        print('Error al confirmar el viaje: $message');
        throw Exception(message);
      }
    } else {
      print('Formato de respuesta inesperado: ${response.body}');
      throw Exception('Formato de respuesta inesperado.');
    }
  } catch (e) {
    print('Error en confirmTravelWithTariff: $e');
    throw Exception('Error al confirmar el viaje: $e');
  }
}

  @override
  Future<void> rejectTravelOffer(TravelwithtariffEntitie travelwithtariffEntitie) async {
    String? savedToken = await AuthService().getToken();

    var response = await http.put(
      Uri.parse(
          '$_baseUrl/app_clients/travels/travels/rejectTravelOffer'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },

      body: jsonEncode(
          TravelwithtariffModal.fromEntity(travelwithtariffEntitie).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el rejectTravelOffer");
    } else {
      String message = body['message'].toString();
      print('error al rejectTravelOffer $body');
      throw Exception(message);
    }
  }

  @override
  Future<void> removedataaccount() async {
    String? savedToken = await AuthService().getToken();

    var response = await http.put(
      Uri.parse('$_baseUrl/app_clients/users/clients/remove'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el removedataaccount");
    } else {
      String message = body['message'].toString();
      print('error al removedataaccount $body');
      throw Exception(message);
    }
  }

  @override
  Future<void> offerNegotiation(
      TravelwithtariffEntitie travelwithtariffEntitie) async {
    String? savedToken = await AuthService().getToken();

    var response = await http.put(
      Uri.parse('$_baseUrl/app_clients/travels/travels/offerNegotiation'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(
          TravelwithtariffModal.fromEntity(travelwithtariffEntitie).toJson()),
    );

    dynamic body = jsonDecode(response.body);
    print(body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      print(message);
      print("si se ejecuto bien el offerNegotiation $message ");
    } else {
      String message = body['message'].toString();
      print('error al offerNegotiation $body');
      throw Exception(message);
    }
  }
  @override
Future<GetcosttravelEntitie> getcosttravel(GetcosttravelEntitie getcosttravelEntitie) async {
  String? savedToken = await AuthService().getToken();
  var response = await http.post(
    Uri.parse('$_baseUrl/app_clients/travels/travels/cost'),
    headers: {
      'Content-Type': 'application/json',
      'x-token': savedToken ?? '',
    },
    body: jsonEncode(
        GetcosttravelModel.fromEntity(getcosttravelEntitie).toJson()),
  );
  
  final jsonResponse = json.decode(response.body);
  print('Respuesta JSON completa: $jsonResponse');
  
  if (response.statusCode == 200) {
    if (jsonResponse['data'] != null) {
             return GetcosttravelModel(
          kilometers: getcosttravelEntitie.kilometers,
          duration: getcosttravelEntitie.duration,
          message: jsonResponse['message'],
          data: jsonResponse['data'],
        );
 } else {
      throw Exception("No se encontró la clave 'data' en la respuesta.");
    }
  } else {
    String message = jsonResponse['message'].toString();
    print('Error en el servidor: $jsonResponse');
    throw Exception(message);
  }
}
}