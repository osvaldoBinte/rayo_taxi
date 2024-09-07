import 'package:rayo_taxi/features/Clients/domain/entities/client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/client_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:convert' as convert;

abstract class ClientLocalDataSource {
  Future<void> createClient(Client client);
  Future<void> loginClient(Client client);
  Future<bool> verifyToken();
  Future<String?> getDeviceId();
  Future<List<ClientModel>> getClient();
}

class ClientLocalDataSourceImp implements ClientLocalDataSource {
  final String _baseUrl =
      'https://developer.binteapi.com:3009/api/app_clients/users';
  @override
  Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      print('Device: $androidInfo');
      return androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      print(iosInfo.identifierForVendor);
      return iosInfo.identifierForVendor;
    }
    return null;
  }

@override
Future<bool> verifyToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token'); // Usamos 'auth_token'

  if (token != null) {
    var response = await http.get(
      Uri.parse('$_baseUrl/auth/renew'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': token,
      },
    );

    dynamic body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      // Guardamos el nuevo token renovado en 'auth_token'
      String newToken = body['data']['token'].toString(); // Tomamos el nuevo token
      await prefs.setString('auth_token', newToken); // Lo guardamos
      print('Nuevo auth_token: ' + newToken);
      return true;
    } else {
      // El token no es válido o la renovación falló
      print('Token no válido o fallo en la renovación');
      await prefs.remove('auth_token'); // Eliminamos el token inválido
      return false;
    }
  } else {
    // No hay token en SharedPreferences
    return false;
  }
}



  @override
  Future<void> loginClient(Client client) async {
    var response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(ClientModel.fromEntity(client).toJson()),
    );

    dynamic body = jsonDecode(response.body);

    print(response.statusCode);
    if (response.statusCode == 200) {
      String message = body['message'].toString();
      String token = body['data']['token'].toString();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('auth_token: ' + token);
      print(message);
    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }

  @override
  Future<void> createClient(Client client) async {
    var response = await http.post(
      Uri.parse('$_baseUrl/clients'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(ClientModel.fromEntity(client).toJson()),
    );

    dynamic body = jsonDecode(response.body);

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

  @override
  Future<List<ClientModel>> getClient() async {
    var response = await http.get(Uri.parse('$_baseUrl/2'));

    if (response.statusCode == 200) {
      final jsonResponse = convert.jsonDecode(response.body);
      if (jsonResponse['ok'] == true && jsonResponse['data'] != null) {
        return (jsonResponse['data'] as List)
            .map<ClientModel>((data) => ClientModel.fromJson(data))
            .toList();
      } else {
        throw Exception('Estructura de respuesta inesperada');
      }
    } else {
      throw Exception('Error en la petición: ${response.statusCode}');
    }
  }
}
