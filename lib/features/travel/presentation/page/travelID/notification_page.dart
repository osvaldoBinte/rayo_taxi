import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travelID/animated_modal_bottom.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travelID/travel_id_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travelID/widgets.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import '../../Travelgetx/TravelsAlert/travels_alert_getx.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:quickalert/quickalert.dart';
import 'widgets.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPage();
}

class _NotificationPage extends State<NotificationPage> {
  final TravelsAlertGetx travelAlertGetx = Get.find<TravelsAlertGetx>();
  late StreamSubscription<ConnectivityResult> subscription;
  final CurrentTravelGetx _travelAlertGetx = Get.find<CurrentTravelGetx>();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
      _travelAlertGetx.fetchCoDetails(FetchgetDetailsssEvent());
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
        _travelAlertGetx.fetchCoDetails(FetchgetDetailsssEvent());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                child: Obx(() {
                  if (travelAlertGetx.state.value is TravelsAlertLoading) {
                    return Center(child: CircularProgressIndicator());
                  } else if (travelAlertGetx.state.value
                      is TravelsAlertFailure) {
                    return _buildListOption(
                      icon: Icons.error,
                      title: 'no hay viajes aun',
                      subtitle: '',
                    );
                  } else if (travelAlertGetx.state.value
                      is TravelsAlertLoaded) {
                    var travels =
                        (travelAlertGetx.state.value as TravelsAlertLoaded)
                            .travels;

                    return RefreshIndicator(
                      onRefresh: _refreshTravels,
                      child: ListView.builder(
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
                                          if (travels[index].id_status != 2)

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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .iconred,
                                      ),
                                      onPressed: () async {
                                        QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.error,
                                          title: 'Cancelar viaje',
                                          text:
                                              '¿Estás seguro de que deseas cancelar este viaje?',
                                          confirmBtnText: 'Sí',
                                          cancelBtnText: 'No',
                                          showCancelBtn: true,
                                          onConfirmBtnTap: () async {
                                            Navigator.of(context)
                                                .pop(); 
                                            await _deleteTravelGetx
                                                .deleteTravel(
                                              DeleteTravelEvent(
                                                  travels[index].id.toString()),
                                            );
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content:
                                                      Text('Viaje cancelado')),
                                            );
                                            await _refreshTravels();
                                          },
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                              onTap: () {
                             
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                  ),
                                  builder: (BuildContext context) {
                                    return FractionallySizedBox(
                                      heightFactor: 0.8,
                                      child: Column(
                                        children: <Widget>[
                                          SizedBox(
                                            height: 10,
                                            width: 70,
                                            child: DecoratedBox(
                                                decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(8)),
                                            )),
                                          ),
                                          Expanded(
                                            child: TravelIdPage(travel:  travels[index],
                                             
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return _buildListOption(
                      icon: Icons.error,
                      title: 'no hay viajes aun',
                      subtitle: '',
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
