import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel/current_travel.dart';
import 'package:rayo_taxi/features/travel/presentation/page/direcionDestino/destino_page.dart';
import 'package:rayo_taxi/features/travel/data/datasources/socket_driver_data_source.dart'; // Importar clase del socket

class SelectMap extends StatefulWidget {
  @override
  _SelectMapState createState() => _SelectMapState();
}

class _SelectMapState extends State<SelectMap> {
  final CurrentTravelGetx currentTravelGetx = Get.find<CurrentTravelGetx>();

  @override
  void initState() {
    super.initState();
    currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final state = currentTravelGetx.state.value;
        if (state is TravelAlertLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is TravelAlertLoaded) {
          return MapContent(travelList: state.travel);
        } else if (state is TravelAlertFailure) {
          return MapContent(travelList: []);
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      }),
    );
  }
}

class MapContent extends StatefulWidget {
  final List<TravelAlertModel> travelList;

  MapContent({required this.travelList});

  @override
  _MapContentState createState() => _MapContentState();
}

class _MapContentState extends State<MapContent> with WidgetsBindingObserver {
  SocketDriverDataSource? socketHandler;
  bool _hasActiveTravel = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateTravelState();
  }

  @override
  void didUpdateWidget(MapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Verifica si el estado de viajes activos cambió
    if (widget.travelList.isEmpty != oldWidget.travelList.isEmpty) {
      _updateTravelState();
    }
  }
  
  void _updateTravelState() {
    bool hasActiveTravel = widget.travelList.isNotEmpty;
    
    // Solo tomar acción si el estado cambió
    if (_hasActiveTravel != hasActiveTravel) {
      _hasActiveTravel = hasActiveTravel;
      
      if (!hasActiveTravel) {
        // Si ya no hay viajes activos, desconectar socket
        _disconnectSocketIfNeeded();
      }
    }
  }
  
  void _disconnectSocketIfNeeded() {
    try {
      if (socketHandler != null) {
        print("MapContent: Desconectando socket cliente porque no hay viajes activos");
        socketHandler!.disconnect();
        socketHandler = null;
      }
    } catch (e) {
      print("MapContent: Error al desconectar socket: $e");
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_hasActiveTravel) {
        _disconnectSocketIfNeeded();
      }
    }
  }
  
  @override
  void dispose() {
    _disconnectSocketIfNeeded();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Contenido de travelList: ${widget.travelList}");
    
    if (widget.travelList.isNotEmpty) {
      return CurrentTravel(travelList: widget.travelList);
    } else {
      _disconnectSocketIfNeeded();
      return DestinoPage();
    }
  }
}