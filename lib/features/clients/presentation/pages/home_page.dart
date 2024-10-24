  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart'; // Import necesario
  import 'package:curved_navigation_bar/curved_navigation_bar.dart';
  import 'package:get/get.dart';
  import 'package:rayo_taxi/features/clients/presentation/pages/get_client_page.dart';
  import 'package:rayo_taxi/features/clients/presentation/pages/home/select_map.dart';
  import 'package:rayo_taxi/main.dart';
  import '../../../notification/presentetion/page/notification_page.dart';
  import 'package:permission_handler/permission_handler.dart';
  import 'package:device_info_plus/device_info_plus.dart';

  // Importa Geolocator
  import 'package:geolocator/geolocator.dart';

  class HomePage extends StatefulWidget {
    @override
    _MyHomePageState createState() => _MyHomePageState();
  }

  class _MyHomePageState extends State<HomePage> {
    final List<Widget> _pages = [
      NotificationPage(),
      SelectMap(),
      GetClientPage(),
    ];

    int _selectedIndex = 1;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    requestPermissionsAndLocation();
  });
}

    Future<void> requestPermissionsAndLocation() async {
      // Solicitar permisos de notificaciones
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          var notificationStatus = await Permission.notification.status;
          if (!notificationStatus.isGranted) {
            notificationStatus = await Permission.notification.request();
            if (notificationStatus.isGranted) {
              print('Permiso de notificaciones concedido');
            } else {
              print('Permiso de notificaciones denegado');
            }
          } else {
            print('Permiso de notificaciones ya concedido');
          }
        }
      }

      // Continuamos solicitando los permisos de ubicación
      await _handleLocationPermission();
    }

    Future<void> _handleLocationPermission() async {
      // Verificar si el servicio de GPS está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Mostrar una alerta al usuario para que active el GPS
        await _showLocationServicesDialog();
        // Después de que el usuario intente activarlo, verificar de nuevo
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('Los servicios de ubicación siguen deshabilitados.');
          // Puedes decidir si quieres continuar o no en este punto
          return;
        }
      }

      // Verificar el estado de los permisos
      LocationPermission permission = await Geolocator.checkPermission();
      print('Estado inicial del permiso de ubicación: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('Permiso de ubicación después de solicitarlo: $permission');
        if (permission == LocationPermission.denied) {
          // Los permisos están denegados de nuevo
          print('Permiso de ubicación denegado.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Los permisos están denegados permanentemente
        print('Permiso de ubicación denegado permanentemente.');
        await openAppSettings();
        return;
      }

      // En este punto, tenemos los permisos necesarios y podemos obtener la ubicación
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        print('Ubicación actual: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('Error al obtener la ubicación: $e');
      }
    }

    Future<void> _showLocationServicesDialog() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // El usuario debe interactuar con el diálogo
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Servicios de Ubicación Desactivados'),
            content: Text(
                'Para utilizar esta aplicación, por favor activa los servicios de ubicación.'),
            actions: <Widget>[
              TextButton(
                child: Text('Activar'),
                onPressed: () async {
                  // Abrir la configuración de ubicación del dispositivo
                  await Geolocator.openLocationSettings();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Puedes decidir qué hacer si el usuario cancela
                },
              ),
            ],
          );
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ));

      bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

      return Scaffold(
        extendBody: true,
        body: SafeArea(
          child: Stack(
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Offstage(
                  offstage: isKeyboardVisible,
                  child: CurvedNavigationBar(
                    index: _selectedIndex,
                    backgroundColor: Colors.transparent,
                    color: Theme.of(context).primaryColor,
                    buttonBackgroundColor:
                        Theme.of(context).colorScheme.CurvedIconback,
                    height: 75,
                    items: <Widget>[
                      _buildIcon(Icons.receipt, 0),
                      _buildIcon(Icons.car_rental, 1),
                      _buildIcon(Icons.person, 2),
                    ],
                    animationDuration: const Duration(milliseconds: 700),
                    animationCurve: Curves.easeInOut,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildIcon(IconData icon, int index) {
      bool isSelected = _selectedIndex == index;
      return Container(
        margin: EdgeInsets.only(bottom: isSelected ? 4 : 0),
        height: isSelected ? 40 : 60,
        child: Icon(
          icon,
          size: isSelected ? 30 : 40,
          color: isSelected
              ? Theme.of(context).colorScheme.CurvedNavigationIcono
              : Theme.of(context).colorScheme.CurvedNavigationIcono2,
        ),
      );
    }
  }
