import 'package:flutter/material.dart';

  Widget _buildListOption(
      {required IconData icon,
      required String title,
      required String subtitle,
      Widget? trailing}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color, Function onPressed,
      {double? top, double? right, double? bottom, double? left}) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        onPressed: () async => await onPressed(),
      ),
    );
  }
