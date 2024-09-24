import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import '../getx/TravelsAlert/travels_alert_getx.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPage();
}

class _NotificationPage extends State<NotificationPage> {
  final TravelsAlertGetx travelAlertGetx = Get.find<TravelsAlertGetx>();
  late StreamSubscription<ConnectivityResult> subscription;
  final TravelAlertGetx _travelAlertGetx = Get.find<TravelAlertGetx>();

  @override
  void initState() {
    super.initState();
    travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
    _travelAlertGetx.fetchCoDetails(FetchgetDetailsEvent());

    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se perdió la conectividad Wi-Fi'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
        _travelAlertGetx.fetchCoDetails(FetchgetDetailsEvent());
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  Icon getStatusIcon(String status) {
    switch (status) {
      case 'Completado':
        return Icon(Icons.check_circle, color: Colors.white, size: 28);
      case 'Buscando Taxi':
        return Icon(Icons.local_taxi, color: Colors.white, size: 28);
      case 'Viaje Cancelado':
        return Icon(Icons.cancel, color: Colors.white, size: 28);
      case 'Viaje Completado':
        return Icon(Icons.done_all, color: Colors.white, size: 28);
      default:
        return Icon(Icons.help_outline,
            color: Colors.white, size: 28); // Icono predeterminado
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Completado':
        return Colors.green;
      case 'Buscando Taxi':
        return Colors.orange;
      case 'Viaje Cancelado':
        return Colors.red;
      case 'Viaje Completado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007BFF), Color(0xFF00A8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Último viaje',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Obx(() {
                if (_travelAlertGetx.state.value is TravelAlertLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (_travelAlertGetx.state.value is TravelAlertFailure) {
                  return Center(
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Ocurrió un error',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (_travelAlertGetx.state.value is TravelAlertLoaded) {
                  var travels =
                      (_travelAlertGetx.state.value as TravelAlertLoaded)
                          .travels;

                  if (travels.isNotEmpty) {
                    var lastTravel = travels.last;
                    return Card(
                      elevation: 6,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        leading: CircleAvatar(
                          backgroundColor: getStatusColor(lastTravel.status),
                          radius: 30,
                          child: getStatusIcon(lastTravel.status),
                        ),
                        title: Text(
                          'Último viaje',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF333333),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            Text(
                              '${lastTravel.status}',
                              style: TextStyle(color: Colors.black87),
                            ),
                            SizedBox(height: 8),
                            Text(
                              lastTravel.date,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'No hay viajes aún',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  return Center(child: Text('No hay datos disponibles.'));
                }
              }),
              SizedBox(height: 20),
              Text(
                'Viajes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (travelAlertGetx.state.value is TravelsAlertLoading) {
                    return Center(child: CircularProgressIndicator());
                  } else if (travelAlertGetx.state.value
                      is TravelsAlertFailure) {
                    return Center(
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Ocurrió un error',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (travelAlertGetx.state.value
                      is TravelsAlertLoaded) {
                    var travels =
                        (travelAlertGetx.state.value as TravelsAlertLoaded)
                            .travels;

                    return ListView.builder(
                      itemCount: travels.length,
                      itemBuilder: (context, index) {
                        return Card(
                            elevation: 6,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              leading: CircleAvatar(
                                backgroundColor:
                                    getStatusColor(travels[index].status),
                                radius: 30,
                                child: getStatusIcon(travels[index].status),
                              ),
                              title: Text(
                                travels[index].status,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 5),
                                  Text(
                                    'Kilómetros: ${travels[index].kilometers}',
                                    style: TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    travels[index].date,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                                size: 18,
                              ),
                            ));
                      },
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'No hay viajes aún',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
