import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/mapa/presentation/page/animated_modal_bottom.dart';
import 'package:rayo_taxi/features/travel/presentetion/getx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/main.dart';
import '../getx/TravelsAlert/travels_alert_getx.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _NotificationPage();
}

class _NotificationPage extends State<TravelPage> {
  final TravelsAlertGetx travelAlertGetx = Get.find<TravelsAlertGetx>();
  late StreamSubscription<ConnectivityResult> subscription;
  final TravelAlertGetx _travelAlertGetx = Get.find<TravelAlertGetx>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
      _travelAlertGetx.fetchCoDetails(FetchgetDetailsEvent());
    });
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

  Icon getStatusIcon(int status) {
    switch (status) {
      case 4:
        return Icon(Icons.check_circle,
            color: Theme.of(context).colorScheme.getStatusIcon, size: 28);
      case 1:
        return Icon(Icons.local_taxi,
            color: Theme.of(context).colorScheme.getStatusIcon, size: 28);
      case 2:
        return Icon(Icons.cancel,
            color: Theme.of(context).colorScheme.getStatusIcon, size: 28);
      case 3:
        return Icon(Icons.done_all,
            color: Theme.of(context).colorScheme.getStatusIcon, size: 28);
    case 5:
    return Icon(Icons.check_circle_outline,
        color: Theme.of(context).colorScheme.getStatusIcon, size: 28);

      default:
        return Icon(Icons.help_outline,
            color: Theme.of(context).colorScheme.getStatusIcon, size: 28);
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 4:
        return Theme.of(context).colorScheme.StatusCompletado;
      case 1:
        return Theme.of(context).colorScheme.StatusLookingfor;
      case 2:
        return Theme.of(context).colorScheme.Statuscancelled;
      case 3:
        return Theme.of(context).colorScheme.Statusaccepted;
      case 5:
        return Theme.of(context).colorScheme.StatusCompletado;
      default:
        return Theme.of(context).colorScheme.Statusrecognized;
    }
  }

  Future<void> _refreshTravels() async {
    travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
    _travelAlertGetx.fetchCoDetails(FetchgetDetailsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Mis viajes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.buttonColormap,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  onRefresh:
                      _refreshTravels, // Funcionalidad para deslizar y refrescar
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
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom +
                              75.0 +
                              16.0,
                        ),
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
                                    getStatusColor(travels[index].id_status),
                                radius: 30,
                                child: getStatusIcon(travels[index].id_status),
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
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (BuildContext context) {
                                    return AnimatedModalBottomSheet(
                                      idTravel: travels[index].id,
                                    );
                                  },
                                );
                              },
                            ),
                          );
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
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
