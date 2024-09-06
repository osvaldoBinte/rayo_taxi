import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/Clients/presentation/getxs/Device/device_getx.dart';


class Homeprueba extends StatelessWidget {
 
  final DeviceGetx _deviceGetx = Get.find<DeviceGetx>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Prueba'),
      ),
      body: Center(
        child: Obx(() {
          if (_deviceGetx.deviceState.value is DeviceInitial) {
            return Text('Presiona el botón para obtener el ID del dispositivo');
          } else if (_deviceGetx.deviceState.value is DeviceLoading) {
            return CircularProgressIndicator();
          } else if (_deviceGetx.deviceState.value is DeviceSuccessfully) {
            return Text('ID del dispositivo obtenido con éxito');
          } else if (_deviceGetx.deviceState.value is DeviceError) {
            return Text('Error: ${( _deviceGetx.deviceState.value as DeviceError).message}');
          }
          return Container();
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _deviceGetx.getDeviceId(); 
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
