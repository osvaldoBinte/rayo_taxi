import 'package:get/get.dart';
import 'package:rayo_taxi/features/driver/domain/entities/driver.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:convert' as convert;
import '../../../travel/presentetion/getx/Device/device_getx.dart';
import '../models/driver_model.dart';

abstract class DriverLocalDataSource {
  Future<void> loginDriver(Driver driver);
  Future<List<DriverModel>> getDriver(bool conection);
}

class DriverLocalDataSourceImp implements DriverLocalDataSource {
  final String _baseUrl =
      'https://developer.binteapi.com:3009/api/app_drivers/users';
  
  @override
  Future<void> loginDriver(Driver driver) async {
      final DeviceGetx _driverGetx = Get.find<DeviceGetx>();

    var response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(DriverModel.fromEntity(driver).toJson()),
    );

    dynamic body = jsonDecode(response.body);

    print(response.statusCode);
    if (response.statusCode == 200) {
      String message = body['message'].toString();
      String token = body['data']['token'].toString();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('auth_token: ' + token);
      await _driverGetx.getDeviceId();
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
  Future<List<DriverModel>> getDriver(bool conection) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String? token = await _getToken();
    if (token == null) {
      throw Exception('Token no disponible');
    }

    if (conection) {
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
            List<DriverModel> clients = [DriverModel.fromJson(data)];

            sharedPreferences.setString('drives', jsonEncode(clients));

            return clients;
          } else {
            throw Exception('Estructura de respuesta inesperada');
          }
        } else {
          throw Exception('Error en la petición: ${response.statusCode}');
        }
      } catch (e) {
        return _loadDrivesFromLocal(sharedPreferences);
      }
    } else {
      return _loadDrivesFromLocal(sharedPreferences);
    }
  }

  Future<List<DriverModel>> _loadDrivesFromLocal(
      SharedPreferences sharedPreferences) async {
    String drivesString = sharedPreferences.getString('drives') ?? "[]";
    List<dynamic> body = jsonDecode(drivesString);

    if (body.isNotEmpty) {
      return body
          .map<DriverModel>((drives) => DriverModel.fromJson(drives))
          .toList();
    } else {
      throw Exception('No hay drives almacenados localmente.');
    }
  }
}
