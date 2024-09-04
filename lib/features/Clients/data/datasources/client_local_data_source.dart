import 'package:rayo_taxi/features/Clients/domain/entities/client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/client_model.dart';

abstract class ClientLocalDataSource {
  Future<void> createClient(Client client);
  Future<void> loginClient(Client client);
  Future<bool> verifyToken();
}

class ClientLocalDataSourceImp implements ClientLocalDataSource {
  final String _baseUrl =
      'https://developer.binteapi.com:3009/api/app_clients/users';
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
        return true;
      }
    }
    return false; 
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
}
