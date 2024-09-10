import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

AppBar buildAppBar(String title) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(255, 2, 2, 2),
      ),
    ),
    backgroundColor: Color.fromARGB(255, 255, 255, 255), // Cambiado a #EFC300
    elevation: 0,
  );
}

CurvedNavigationBar buildBottomNavigationBar(int pageIndex, Function(int) onTap) {
  return CurvedNavigationBar(
    backgroundColor: Colors.transparent,
    color: const Color(0xFFEFC300), // Cambiado a #EFC300
    buttonBackgroundColor: Colors.orangeAccent,
    height: 60,
    items: const <Widget>[
      Icon(Icons.person, size: 30, color: Colors.white),
      Icon(Icons.edit, size: 30, color: Colors.white),
      Icon(Icons.settings, size: 30, color: Colors.white),
    ],
    onTap: onTap,
    animationDuration: const Duration(milliseconds: 300),
    animationCurve: Curves.easeInOut,
  );
}
