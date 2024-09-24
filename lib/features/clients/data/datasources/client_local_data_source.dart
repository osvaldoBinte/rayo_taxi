import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/domain/entities/client.dart';
import 'package:http/http.dart' as http;
import 'package:rayo_taxi/features/notification/presentetion/getx/Device/device_getx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/client_model.dart';
import 'dart:io';
import 'dart:convert' as convert;
import 'package:intl/intl.dart';

abstract class ClientLocalDataSource {
  Future<void> createClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> loginClient(Client client);
  Future<bool> verifyToken();
  Future<String?> getDeviceId();
  Future<List<ClientModel>> getClient(bool conection);
  int calcularEdad(String birthdate);
}

class ClientLocalDataSourceImp implements ClientLocalDataSource {
  final String _baseUrl =
      'https://developer.binteapi.com:3009/api/app_clients/users';

  @override
  int calcularEdad(String birthdate) {
    try {
      final DateTime fechaNacimiento =
          DateFormat('dd/MM/yyyy').parse(birthdate);
      final DateTime hoy = DateTime.now();
      int edad = hoy.year - fechaNacimiento.year;

      if (hoy.month < fechaNacimiento.month ||
          (hoy.month == fechaNacimiento.month &&
              hoy.day < fechaNacimiento.day)) {
        edad--;
      }

      return edad;
    } catch (e) {
      return 0; // Retorna 0 si no se puede calcular la edad
    }
  }

  @override
  Future<List<ClientModel>> getClient(bool connection) async {
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

        var response = await http.get(
          Uri.parse('$_baseUrl/auth/renew'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final jsonResponse = convert.jsonDecode(response.body);
          if (jsonResponse['data'] != null) {
            var data = jsonResponse['data'];
            List<ClientModel> clients = [ClientModel.fromJson(data)];

            sharedPreferences.setString('clients', jsonEncode(clients));
            print("holaaa  aa");
            return clients;
          } else {
            throw Exception('Estructura de respuesta inesperada');
          }
        } else {
          throw Exception('Error en la petición: ${response.statusCode}');
        }
      } catch (e) {
        return _loadClientsFromLocal(sharedPreferences);
      }
    } else {
      return _loadClientsFromLocal(sharedPreferences);
    }
  }

  Future<List<ClientModel>> _loadClientsFromLocal(
      SharedPreferences sharedPreferences) async {
    String clientsString = sharedPreferences.getString('clients') ?? "[]";
    List<dynamic> body = jsonDecode(clientsString);

    if (body.isNotEmpty) {
      return body
          .map<ClientModel>((client) => ClientModel.fromJson(client))
          .toList();
    } else {
      throw Exception('No hay clientes almacenados localmente.');
    }
  }

  @override
  Future<bool> verifyToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

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
        String newToken = body['data']['token'].toString();
        await prefs.setString('auth_token', newToken);
        print('Nuevo auth_token: ' + newToken);
        return true;
      } else {
        print('Token no válido o fallo en la renovación');
        await prefs.remove('auth_token');
        return false;
      }
    } else {
      return false;
    }
  }

  @override
  Future<void> loginClient(Client client) async {
    final DeviceGetx _driverGetx = Get.find<DeviceGetx>();

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
      bool isSaved = await prefs.setString('auth_token', token);

      if (isSaved) {
        print('Token guardado correctamente: $token');
        String? savedToken = prefs.getString('auth_token');
        print('Token recuperado de SharedPreferences: $savedToken');
        await _driverGetx.getDeviceId();
      } else {
        print('Error al guardar el token');
      }

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

  Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Future<void> updateClient(Client client) async {
    String? savedToken = await _getToken();

    var response = await http.put(
      Uri.parse('$_baseUrl/clients'),
      headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(ClientModel.fromEntity(client).toJson()),
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

  @override
  Future<String?> getDeviceId() {
    // TODO: implement getDeviceId
    throw UnimplementedError();
  }
}
