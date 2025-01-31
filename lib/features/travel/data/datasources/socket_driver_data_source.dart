import 'dart:async';

import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

abstract class SocketDriverDataSource {
  void connect();
  void joinTravel(String idTravel);
  void updateLocation(String idTravel, Map<String, dynamic> location);
  void disconnect();
  String? get socketId;
  Stream<Map<String, dynamic>> get locationUpdates;
}

class SocketDriverDataSourceImpl implements SocketDriverDataSource {
  late IO.Socket socket;
  final _locationController = StreamController<Map<String, dynamic>>.broadcast();
  
  @override
  String? get socketId => socket.id;
    String baseUrl = AppConstants.serverBase;

  @override
  Stream<Map<String, dynamic>> get locationUpdates => _locationController.stream;
    SocketDriverDataSourceImpl() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('TaxiInfo Socket conectado con ID: ${socket.id}');
    });

    socket.onDisconnect((_) {
      print('TaxiInfo Socket desconectado');
    });

    socket.onDisconnect((_) {
      print('Desconectado del servidor');
    });

  socket.on('driver_location_update', (data) {
      print('TaxiInfo Socket recibió datos: $data');
      try {
        if (data != null) {
          final Map<String, dynamic> locationData = Map<String, dynamic>.from(data);
          print('TaxiInfo Enviando datos al stream: $locationData');
          _locationController.add(locationData);
        }
      } catch (e) {
        print('TaxiInfo Error procesando datos del socket: $e');
      }
    });
  }
  

  @override
  void connect() {
    try {
      socket.connect();
      print('TaxiInfo Intentando conectar socket');
    } catch (e) {
      print('TaxiInfo Error conectando socket: $e');
    }
  }
  @override
  void joinTravel(String idTravel) {
    socket.emit('join_travel', {'id_travel': idTravel});
  }

  @override
  void updateLocation(String idTravel, Map<String, dynamic> location) {
    socket.emit('update_driver_location', {
      'id_travel': idTravel,
      'location': location
    });
  }

   @override
  void disconnect() {
    try {
      socket.disconnect();
      _locationController.close();
      print('TaxiInfo Socket desconectado y stream cerrado');
    } catch (e) {
      print('TaxiInfo Error desconectando socket: $e');
    }
  }

}