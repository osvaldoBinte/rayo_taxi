import 'package:rayo_taxi/features/Clients/domain/entities/client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/client_model.dart';

abstract class ClientLocalDataSource {
  Future<void> createClient(Client client);
}

class ClientLocalDataSourceImp implements ClientLocalDataSource {
  final String _baseUrl =
      'https://developer.binteapi.com:3009/api/app_clients/users/';

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
