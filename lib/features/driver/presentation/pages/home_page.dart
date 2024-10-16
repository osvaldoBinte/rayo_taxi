import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rayo_taxi/features/mapa/presentation/midireccion_page.dart';
import 'package:rayo_taxi/features/mapa/presentation/page/mapa/select_map.dart';
import 'package:rayo_taxi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../travel/presentetion/page/travel_page.dart';
import 'get_driver_page.dart';
import 'login_driver_page.dart';

class HomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  final List<Widget> _pages = [
    TravelPage(),
    SelectMap(),
    GetDriverPage(),
  ];

  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _checkAuthToken();
    _requestNotificationPermission(); // Solicitar permisos de notificación
  }

  // Solicitar permisos de notificación
  Future<void> _requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  // Método para verificar el token en SharedPreferences
  Future<void> _checkAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      // Si el token no está presente, redirigir al login
      Future.microtask(() => Get.offAll(() => LoginDriverPage()));
    }
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
