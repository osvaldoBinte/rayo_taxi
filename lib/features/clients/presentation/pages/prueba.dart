import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/get_client_page.dart';

import '../../../travel/presentation/page/mapa.dart';
//import 'package:rayo_taxi/features/travel/presentation/page/mapa_page.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Home Screen')),
    );
  }
}



class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Widget> _pages = [
    HomeScreen(),
    MapScreen(),
    GetClientPage(),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], 
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: const Color(0xFFEFC300), 
        buttonBackgroundColor: Colors.orangeAccent,
        height: 60,
        items: const <Widget>[
          Icon(Icons.edit, size: 30, color: Colors.white),
          Icon(Icons.car_rental, size: 30, color: Colors.white),
          Icon(Icons.edit, size: 30, color: Colors.white),
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
