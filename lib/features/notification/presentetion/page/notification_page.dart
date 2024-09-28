import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/notification/presentetion/page/widgets.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/main.dart';
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
  final DeleteTravelGetx _deleteTravelGetx = Get.find<DeleteTravelGetx>();

  Future<void> _refreshTravels() async {
    await Future.wait([
      travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent()),
     _travelAlertGetx.fetchCoDetails(FetchgetDetailsssEvent()),
    ] as Iterable<Future>);
  }

  @override
  void initState() {
    super.initState();
    travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
    _travelAlertGetx.fetchCoDetails(FetchgetDetailsssEvent());

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
        _travelAlertGetx.fetchCoDetails(FetchgetDetailsssEvent());
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
        return Icon(Icons.check_circle,
            color: Theme.of(context).colorScheme.iconwhite, size: 28);
      case 'Buscando Taxi':
        return Icon(Icons.local_taxi,
            color: Theme.of(context).colorScheme.iconwhite, size: 28);
      case 'Viaje Cancelado':
        return Icon(Icons.cancel,
            color: Theme.of(context).colorScheme.iconwhite, size: 28);
      case 'Viaje Completado':
        return Icon(Icons.done_all,
            color: Theme.of(context).colorScheme.iconwhite, size: 28);
      default:
        return Icon(Icons.help_outline,
            color: Theme.of(context).colorScheme.iconwhite, size: 28);
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Completado':
        return Theme.of(context).colorScheme.icongreen;
      case 'Buscando Taxi':
        return Theme.of(context).colorScheme.iconorange;
      case 'Viaje Cancelado':
        return Theme.of(context).colorScheme.iconred;
      case 'Viaje Completado':
        return Theme.of(context).colorScheme.iconblue;
      default:
        return Theme.of(context).colorScheme.icongrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshTravels,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ], 
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Último viaje',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  SizedBox(height: 10),
                  Obx(() {
                    if (_travelAlertGetx.state.value is TravelAlertLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (_travelAlertGetx.state.value
                        is TravelAlertFailure) {
                      return NoDataCard(
                        message: 'Ocurrió un error',
                      );
                    } else if (_travelAlertGetx.state.value
                        is TravelAlertLoaded) {
                      var travels =
                          (_travelAlertGetx.state.value as TravelAlertLoaded)
                              .travel;

                      if (travels.isNotEmpty) {
                        var lastTravel = travels.last;

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
                                  getStatusColor(lastTravel.status),
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
                                Text(
                                  'Kilómetros: ${lastTravel.kilometers}',
                                  style: TextStyle(
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            trailing: (lastTravel.status == 'Buscando Taxi')
                                ? IconButton(
                                    icon: Icon(
                                      Icons.cancel,
                                      color: Theme.of(context).colorScheme.iconred,
                                    ),
                                    onPressed: () async {
                                      bool confirm = await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Cancelar viaje'),
                                          content: Text(
                                              '¿Estás seguro de que deseas cancelar este viaje?'),
                                          actions: [
                                            TextButton(
                                              child: Text('No'),
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                            ),
                                            TextButton(
                                              child: Text('Sí'),
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm) {
                                        await _deleteTravelGetx.deleteTravel(
                                            DeleteTravelEvent(
                                                lastTravel.id.toString()));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('Viaje cancelado')),
                                        );
                                        await _refreshTravels();
                                      }
                                    },
                                  )
                                : null,
                          ),
                        );
                      } else {
                        return NoDataCard(
                          message: 'No hay viajes aún',
                        );
                      }
                    } else {
                      return Center(
                          child: Text('No hay datos disponibles.'));
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
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Obx(() {
                      if (travelAlertGetx.state.value
                          is TravelsAlertLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else if (travelAlertGetx.state.value
                          is TravelsAlertFailure) {
                        return NoDataCard(
                          message: 'Ocurrió un error',
                        );
                      } else if (travelAlertGetx.state.value
                          is TravelsAlertLoaded) {
                        var travels = (travelAlertGetx.state.value
                                as TravelsAlertLoaded)
                            .travels;

                        return RefreshIndicator(
                          onRefresh: _refreshTravels,
                          child: ListView.builder(
                            padding: EdgeInsets.only(
                              bottom: 75.0 + 16.0,
                            ),
                            itemCount: travels.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 6,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: ListTile(
                                  contentPadding:
                                      EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 16),
                                  leading: CircleAvatar(
                                    backgroundColor: getStatusColor(
                                        travels[index].status),
                                    radius: 30,
                                    child: getStatusIcon(
                                        travels[index].status),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  trailing: (travels[index].status ==
                                          'Buscando Taxi')
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.cancel,
                                            color: Theme.of(context).colorScheme.iconred,
                                          ),
                                          onPressed: () async {
                                            bool confirm =
                                                await showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  AlertDialog(
                                                title:
                                                    Text('Cancelar viaje'),
                                                content: Text(
                                                    '¿Estás seguro de que deseas cancelar este viaje?'),
                                                actions: [
                                                  TextButton(
                                                    child: Text('No'),
                                                    onPressed: () =>
                                                        Navigator.of(
                                                                context)
                                                            .pop(false),
                                                  ),
                                                  TextButton(
                                                    child: Text('Sí'),
                                                    onPressed: () =>
                                                        Navigator.of(
                                                                context)
                                                            .pop(true),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm) {
                                              await _deleteTravelGetx
                                                  .deleteTravel(
                                                      DeleteTravelEvent(
                                                          travels[index]
                                                              .id
                                                              .toString()));
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Viaje cancelado')),
                                              );
                                              await _refreshTravels();
                                            }
                                          },
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        return NoDataCard(
                          message: 'No hay viajes aún',
                        );
                      }
                    }),
                  ),
                  SizedBox(height: 70),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
