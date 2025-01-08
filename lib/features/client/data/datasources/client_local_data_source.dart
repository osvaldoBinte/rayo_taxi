import 'package:get/get.dart';
import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:rayo_taxi/features/AuthS/AuthService.dart';
import 'package:rayo_taxi/features/client/data/models/genders/genders_model.dart';
import 'package:rayo_taxi/features/client/data/models/recoveryPassword/recovery_password_model.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import 'package:http/http.dart' as http;
import 'package:rayo_taxi/features/client/domain/entities/recoveryPassword/recovery_password_entitie.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/Device/device_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/client_model.dart';
import 'dart:io';
import 'dart:convert' as convert;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

abstract class ClientLocalDataSource {
  Future<void> createClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> loginClient(Client client);
  Future<void> CreaterecoveryCode(RecoveryPasswordEntitie recoveryPasswordEntitie);
  Future<void> checkRecoveryCode(RecoveryPasswordEntitie recoveryPasswordEntitie);
  Future<void> updatePassword(RecoveryPasswordEntitie recoveryPasswordEntitie);

  Future<bool> verifyToken();
  Future<List<ClientModel>> getClient(bool conection);
  Future<List<GendersModel>> getgenders();

  int calcularEdad(String birthdate);
  Future<void> loginGoogle(Client client);
}

class ClientLocalDataSourceImp implements ClientLocalDataSource {
    String _baseUrl = AppConstants.serverBase;
  final logger = Logger();

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
      return 0; 
    }
  }

  @override
  Future<List<ClientModel>> getClient(bool connection) async {
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
    dynamic body = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final jsonResponse = convert.jsonDecode(response.body);
          if (jsonResponse['data'] != null) {
            var data = jsonResponse['data'];

            List<ClientModel> clients = [ClientModel.fromJson(data)];
                  String token = body['data']['token'].toString();

            sharedPreferences.setString('clients', jsonEncode(clients));
            print("");
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
    String? token =  await AuthService().getToken();
        print('ald auth_token: $token');
    if (token == null) {
      
      throw Exception('Token no disponible');
    }
   try{
      var response = await http.get(
        Uri.parse('$_baseUrl/app_clients/users/auth/renew'),
        headers: {
          'Content-Type': 'application/json',
          'x-token': token,
        },
      );

      dynamic body = jsonDecode(response.body);

      if (response.statusCode == 200 ) {
            String newToken = body['token'].toString();

          await AuthService().saveToken(newToken);
        print('Nuevo auth_token: ' + newToken);
        return true;
      } else {
        print('Token no válido o fallo en la renovación');
        //await prefs.remove('auth_token');
        return false;
      }
     } catch (e) {
      print('Token no válid $e');
        return false;
      }
   
  }
@override
Future<void> loginClient(Client client) async {
  final DeviceGetx _driverGetx = Get.find<DeviceGetx>();

  var response = await http.post(
    Uri.parse('$_baseUrl/app_clients/users/auth/login'),
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

    await AuthService().saveToken(token);

    String? savedToken = await AuthService().getToken();
    print('auth_token recuperado después de guardar: $savedToken');

    await _driverGetx.getDeviceId();

    print(message);
  } else {
    String message = body['message'].toString();
    print('error en login client${body}');
    throw Exception(message);
  }
}


  @override
  Future<void> createClient(Client client) async {
    var response = await http.post(
      Uri.parse('$_baseUrl/app_clients/users/clients'),
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
  Future<void> updateClient(Client client) async {
    String? savedToken = await AuthService().getToken();

    var uri = Uri.parse('$_baseUrl/app_clients/users/clients');
    var request = http.MultipartRequest('PUT', uri);

    request.headers['x-token'] = savedToken ?? '';

    request.fields['name'] = client.name ?? '';
    request.fields['birthdate'] = client.birthdate ?? '';
    request.fields['new_password'] = client.new_password ?? '';
    request.fields['current_password'] = client.current_password ?? '';

    if (client.photo_profile != null && client.photo_profile!.isNotEmpty) {
      File imageFile = File(client.photo_profile!);
      request.files.add(
        await http.MultipartFile.fromPath('photo_profile', imageFile.path),
      );
    }

    try {
      var response = await request.send();

      var responseData = await http.Response.fromStream(response);
      if (response.statusCode == 200) {
        dynamic body = jsonDecode(responseData.body);
        print(body);

        if (body['ok'] == true) {
          if (body.containsKey('password')) {
            var passwordStatus = body['password'][0];
            if (!passwordStatus) {
              String passwordErrorMessage = body['password'][1]['message'];

  CustomSnackBar.showError(
                              'Error',
                              passwordErrorMessage,
                            );
           
            } else {

  CustomSnackBar.showSuccess(
                              'Éxito',
                              'Perfil actualizado correctamente',
                            );
           
            }
          } else {
            Get.snackbar('Éxito ', 'Perfil actualizado correctamente',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white);
          }
        } else {
          throw Exception(body['message']);
        }
      } else {
        throw Exception('Error en la actualización');
      }
    } catch (e) {
      throw Exception('Error al actualizar cliente: ${e.toString()}');
    }
  }

  @override
  Future<void> loginGoogle(Client client) async {
    final DeviceGetx _driverGetx = Get.find<DeviceGetx>();

    logger.i('Iniciando solicitud HTTP POST a $_baseUrl/auth/loginWithGoogle');

    final requestStartTime = DateTime.now();
    var response = await http.post(
      Uri.parse('$_baseUrl/app_clients/users/auth/loginWithGoogle'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(ClientModel.fromEntity(client).toJson()),
    );
    final requestDuration = DateTime.now().difference(requestStartTime);
    logger
        .i('Solicitud HTTP completada en ${requestDuration.inMilliseconds} ms');

    dynamic body = jsonDecode(response.body);

    logger.i('Código de estado de la respuesta: ${response.statusCode}');

    if (response.statusCode == 200) {
      String message = body['message'].toString();
      logger.i('Mensaje Google: $message');
      String token = body['data']['token'].toString();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('login_message', message);
      logger.i('auth_token google: $token');

      logger.i('Iniciando _driverGetx.getDeviceId()');
      final deviceIdStartTime = DateTime.now();
      await _driverGetx.getDeviceId();
      final deviceIdDuration = DateTime.now().difference(deviceIdStartTime);
      logger.i(
          '_driverGetx.getDeviceId() completado en ${deviceIdDuration.inMilliseconds} ms');
    } else {
      String message = body['message'].toString();
      logger.e('Error en la respuesta: $message');
      throw Exception(message);
    }
  }

  @override
  Future<List<GendersModel>> getgenders() async {
    final url = Uri.parse('$_baseUrl/app_clients/catalogs/genders');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['ok']) {
          final List<dynamic> data = responseData['data'];
          print('responseData getgenders $responseData');
          return data.map((item) => GendersModel.fromJson(item)).toList();
        } else {
          print('responseData error getgenders $responseData');

          throw Exception('Error: ${responseData['message']}');
        }
      } else {
        print('responseData error getgenders $response');

        throw Exception('Failed to load genders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener géneros: $e');
    }
  }

  @override
  Future<void> CreaterecoveryCode(
      RecoveryPasswordEntitie recoveryPasswordEntitie) async {
    var response = await http.put(
      Uri.parse('$_baseUrl/app_clients/users/auth/create/code'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
          RecoveryPasswordModel.fromEntity(recoveryPasswordEntitie).toJson()),
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
  Future<void> checkRecoveryCode(
      RecoveryPasswordEntitie recoveryPasswordEntitie) async {
    var response = await http.put(
      Uri.parse('$_baseUrl/app_clients/users/auth/check/code'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
          RecoveryPasswordModel.fromEntity(recoveryPasswordEntitie).toJson()),
    );

    dynamic body = jsonDecode(response.body);

    print(response.statusCode);
    if (response.statusCode == 200) {
      String message = body['message'].toString();

      String token = body['data']['token'].toString();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print(message);
    } else {
      String message = body['message'].toString();
      print(body);
      throw Exception(message);
    }
  }
  
  @override
  Future<void> updatePassword(RecoveryPasswordEntitie recoveryPasswordEntitie) async {
        String? savedToken = await AuthService().getToken();

    var response = await http.put(
      Uri.parse('$_baseUrl/app_clients/users/auth/password'),
        headers: {
        'Content-Type': 'application/json',
        'x-token': savedToken ?? '',
      },
      body: jsonEncode(
          RecoveryPasswordModel.fromEntity(recoveryPasswordEntitie).toJson()),
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
}
