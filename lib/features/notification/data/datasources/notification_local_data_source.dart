import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rayo_taxi/features/notification/domain/entities/device.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/device_model.dart';

abstract class NotificationLocalDataSource {
  Future<void> updateIdDevice();
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
      body: jsonEncode(DeviceModel.fromEntity(device)
          .toJson()), 
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
}
