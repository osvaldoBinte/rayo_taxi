import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/get_client_page.dart';
import 'package:rayo_taxi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../notification/presentetion/page/notification_page.dart';
import '../../../travel/presentation/page/mapa.dart';
import 'login_clients_page.dart';
import 'package:flutter/material.dart';

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

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      extendBody: true, 
      body: Stack(
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
                buttonBackgroundColor: Theme.of(context).scaffoldBackgroundColor, 
                height: 75,
                items: <Widget>[
                  _buildIcon(Icons.notifications, 0),
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
        color: isSelected ?  Theme.of(context).colorScheme.CurvedNavigationIcono : Theme.of(context).colorScheme.CurvedNavigationIcono2,
      ),
    );
  }
}
