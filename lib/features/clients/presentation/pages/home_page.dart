import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/get_client_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../notification/presentetion/page/notification_page.dart';
import '../../../travel/presentation/page/mapa.dart';
import 'login_clients_page.dart';



class HomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  final List<Widget> _pages = [
    NotificationPage(),
    MapScreen(),
    GetClientPage(),
  ];
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); 
    Get.offAll(() => LoginClientsPage()); 
  }
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Center(
          child: const Text('Rayo_taxi'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout), 
            onPressed: () async {
              await _logout();
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex], 
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: const Color(0xFFEFC300), 
        buttonBackgroundColor: Colors.orangeAccent,
        height: 60,
        items: const <Widget>[
          Icon(Icons.notifications, size: 30, color: Colors.white),
          Icon(Icons.car_rental, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
