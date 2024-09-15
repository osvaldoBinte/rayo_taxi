import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      'title': 'Nueva oferta disponible',
      'body': '¡Obtén un 20% de descuento en tu próximo viaje!',
      'time': 'Hace 2 horas',
    },
    {
      'title': 'Actualización de tu viaje',
      'body': 'Tu conductor está a 5 minutos de distancia.',
      'time': 'Hace 10 minutos',
    },
    {
      'title': 'Recordatorio de pago',
      'body': 'No olvides completar el pago de tu último viaje.',
      'time': 'Ayer',
    },
    {
      'title': 'Nuevas funciones',
      'body': 'Explora las nuevas funcionalidades en la app.',
      'time': 'Hace 3 días',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  notifications[index]['title']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5),
                    Text(notifications[index]['body']!),
                    SizedBox(height: 5),
                    Text(
                      notifications[index]['time']!,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 18,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
