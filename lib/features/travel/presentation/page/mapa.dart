import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/clients/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/home_page.dart';
import 'package:rayo_taxi/features/notification/presentetion/getx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:rayo_taxi/main.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../connectivity_service.dart';
import '../../../notification/presentetion/getx/TravelAlert/travel_alert_getx.dart';

class MapController extends GetxController {
  final String endControllerText;
  final String startAddress;
  final LatLng? startLatLng;

  MapController({
    required this.endControllerText,
    required this.startAddress,
    required this.startLatLng,
  });

  late GoogleMapController mapController;
  final TravelGetx travelGetx = Get.find<TravelGetx>();
  final DeleteTravelGetx deleteTravelGetx = Get.find<DeleteTravelGetx>();
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();
  final TravelsAlertGetx travelAlertGetx = Get.find<TravelsAlertGetx>();

  // Observables
  RxSet<gmaps.Marker> markers = <gmaps.Marker>{}.obs;
  RxSet<Polyline> polylines = <Polyline>{}.obs;
  Rxn<LatLng> startLocation = Rxn<LatLng>();
  Rxn<LatLng> endLocation = Rxn<LatLng>();
  Rx<LatLng> center = const LatLng(20.676666666667, -103.39182).obs;
  RxString buttonText = "Buscar conductor".obs;
  RxList<dynamic> startPredictions = <dynamic>[].obs;
  RxList<dynamic> endPredictions = <dynamic>[].obs;
  TextEditingController startController = TextEditingController();
  TextEditingController endController = TextEditingController();
  TravelLocalDataSource travelLocalDataSource = TravelLocalDataSourceImp();
  final NotificationController notificationController =
      Get.find<NotificationController>();
 final ModalController modalController =
      Get.find<ModalController>();
  late ConnectivityService connectivityService;

  FocusNode startFocusNode = FocusNode();
  FocusNode endFocusNode = FocusNode();
  RxString currentInputField = 'start'.obs;
  Completer<GoogleMapController> controllerCompleter = Completer();

  // Para manejar el historial de búsqueda
  RxList<Map<String, String>> searchHistory = <Map<String, String>>[].obs;
  RxBool isButtonVisible = true.obs;

  RxString lottieUrl =
      'https://lottie.host/e44ab786-30a1-48ee-96eb-bb2e002f3ae8/NtzqQeAN8j.json'
          .obs;
  RxString modalText = 'Buscando chofer...'.obs;

  @override
  void onInit() {
    super.onInit();
    connectivityService = ConnectivityService();
    endController.text = endControllerText;
    startController.text = startAddress;

    // Si el texto de inicio no está vacío, busca y selecciona la ubicación
    if (startController.text.isNotEmpty) {
      searchAndSelectPlace(startController.text, isStartPlace: true);
    }

    // Si el texto de destino no está vacío, busca y selecciona la ubicación
    if (endController.text.isNotEmpty) {
      searchAndSelectPlace(endController.text, isStartPlace: false);
    }

    startController.addListener(() {
      if (currentInputField.value == 'start') {
        searchPlace(startController.text, isStartPlace: true);

        // Oculta el botón si hay predicciones o historial de búsqueda
        isButtonVisible.value = startPredictions.isEmpty &&
            (startController.text.isNotEmpty || searchHistory.isEmpty);
      }
    });

    endController.addListener(() {
      if (currentInputField.value == 'end') {
        searchPlace(endController.text, isStartPlace: false);

        // Oculta el botón si hay predicciones o historial de búsqueda
        isButtonVisible.value = endPredictions.isEmpty &&
            (endController.text.isNotEmpty || searchHistory.isEmpty);
      }
    });

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        Get.snackbar(
          'Conectividad',
          'Se perdió la conectividad Wi-Fi',
          duration: Duration(seconds: 3),
        );
      }
    });

    startFocusNode.addListener(() {
      if (startFocusNode.hasFocus) {
        currentInputField.value = 'start';
      }
    });

    endFocusNode.addListener(() {
      if (endFocusNode.hasFocus) {
        currentInputField.value = 'end';
      }
    });

    // Aseguramos que las listas de predicciones estén vacías al iniciar
    startPredictions.clear();
    endPredictions.clear();

    // Cargar el historial de búsqueda
    loadSearchHistory();
  }

  Future<void> loadSearchHistory() async {
    searchHistory.value = await travelLocalDataSource.getSearchHistory();
  }

  @override
  void onClose() {
    startController.dispose();
    endController.dispose();
    startFocusNode.dispose();
    endFocusNode.dispose();
    super.onClose();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controllerCompleter.complete(controller);

    if (startLatLng != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(startLatLng!, 15.0),
      );
      addMarker(startLatLng!, true);
    }
  }

  void addMarker(LatLng latLng, bool isStartPlace) {
    if (isStartPlace) {
      markers.removeWhere((m) => m.markerId.value == 'start');
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('start'),
          position: latLng,
          infoWindow: gmaps.InfoWindow(title: 'Inicio'),
        ),
      );
      startLocation.value = latLng;
    } else {
      markers.removeWhere((m) => m.markerId.value == 'destination');
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('destination'),
          position: latLng,
          infoWindow: gmaps.InfoWindow(title: 'Destino'),
        ),
      );
      endLocation.value = latLng;
    }

    if (startLocation.value != null && endLocation.value != null) {
      traceRoute();
    }
  }

  void searchAndSelectPlace(String placeName,
      {required bool isStartPlace}) async {
    if (placeName.isEmpty) return;

    // Obtiene las predicciones de lugares basadas en el nombre
    List<dynamic> predictions =
        await travelLocalDataSource.getPlacePredictions(placeName);

    if (predictions.isNotEmpty) {
      String placeId = predictions.first['place_id'];
      // Selecciona el lugar y agrega el marcador en el mapa
      selectPlace(placeId, isStartPlace);

      // Actualiza el texto del controlador con la descripción del lugar
      if (isStartPlace) {
        startController.text = predictions.first['description'];
      } else {
        endController.text = predictions.first['description'];
      }
    } else {
      print('No se encontraron predicciones para $placeName');
    }
  }

  Future<int?> getSavedTravelId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_travel_id');
  }

  Future<void> traceRoute() async {
    if (startLocation.value != null && endLocation.value != null) {
      try {
        await travelLocalDataSource.getRoute(
            startLocation.value!, endLocation.value!);
        String encodedPoints = await travelLocalDataSource.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            travelLocalDataSource.decodePolyline(encodedPoints);
        polylines.clear();
        polylines.add(Polyline(
          polylineId: PolylineId('route'),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ));
      } catch (e) {
        print('Error al trazar la ruta: $e');
      }
    }
  }
void showRouteDetails(BuildContext context) async {
  if (startLocation.value != null && endLocation.value != null) {
    if (!notificationController.tripAccepted.value) {
      // Si `tripAccepted` es falso, ejecutamos `poshTravel`
      double distance = travelLocalDataSource.calculateDistance(
          startLocation.value!, endLocation.value!);
      double duration = travelLocalDataSource.getDuration();

      final post = Travel(
        start_longitude: startLocation.value!.longitude,
        start_latitude: startLocation.value!.latitude,
        end_longitude: endLocation.value!.longitude,
        end_latitude: endLocation.value!.latitude,
        kilometers: distance.toStringAsFixed(2),
        duration: duration.toStringAsFixed(2),
      );

      await travelGetx.poshTravel(CreateTravelEvent(post));
      await travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
    }

    // Mostrar el modal
    Get.bottomSheet(
      FractionallySizedBox(
        heightFactor: 0.75,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: SizedBox.expand(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Obx(() => SizedBox(
                          height: 300,
                          child: Lottie.network(
                            modalController.lottieUrl.value,
                            fit: BoxFit.contain,
                            repeat: true,
                          ),
                        )),
                    SizedBox(height: 20),
                    Obx(() => Align(
                          alignment: Alignment.center,
                          child: Text(
                            modalController.modalText.value,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        )),
                    SizedBox(height: 20),
                    Obx(() {
                      return notificationController.tripAccepted.value
                          ? SizedBox.shrink()
                          : ElevatedButton(
                              onPressed: () async {
                                int? savedTravelId = await getSavedTravelId();

                                if (savedTravelId != null) {
                                  print('ID del viaje a cancelar: $savedTravelId');

                                  await deleteTravelGetx.deleteTravel(
                                      DeleteTravelEvent(savedTravelId.toString()));

                                  Get.back(); // Cierra el modal
                                } else {
                                  Get.snackbar(
                                    'Error',
                                    'No se encontró un ID de viaje válido',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.buttonColor,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.buttontext),
                              child: Text('Cancelar viaje'),
                            );
                    })
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  } else {
    Get.snackbar(
      'Error',
      'Por favor, ingresa la dirección de inicio y destino.',
      duration: Duration(seconds: 3),
    );
  }
}



  Future<void> searchPlace(String input, {required bool isStartPlace}) async {
    if (input.isEmpty) {
      if (isStartPlace) {
        startPredictions.clear();
      } else {
        endPredictions.clear();
      }
      return;
    }

    LatLng? locationBias;
    if (isStartPlace && startLatLng != null) {
      locationBias = startLatLng;
    }

    List<dynamic> predictions = await travelLocalDataSource.getPlacePredictions(
      input,
      location: locationBias,
    );

    if (isStartPlace) {
      startPredictions.assignAll(predictions);
    } else {
      endPredictions.assignAll(predictions);
    }
  }

  void selectPlace(String placeId, bool isStartPlace) async {
    await travelLocalDataSource.getPlaceDetailsAndMove(
      placeId,
      (LatLng location) {
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );
      },
      (LatLng location) {
        addMarker(location, isStartPlace);
      },
    );

    if (isStartPlace) {
      startPredictions.clear();
    } else {
      endPredictions.clear();
    }

    // Guardar en el historial de búsqueda
    await travelLocalDataSource.saveSearchHistory({
      'place_id': placeId,
      'description': isStartPlace ? startController.text : endController.text,
    });
    loadSearchHistory();
    isButtonVisible.value =
        startController.text.isNotEmpty && endController.text.isNotEmpty;
  }

  void getUserLocation() async {
    try {
      // Verifica y solicita permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Error', 'Permisos de ubicación denegados');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
            'Error', 'Permisos de ubicación denegados permanentemente');
        return;
      }

      // Obtiene la posición actual del usuario
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      // Realiza la geocodificación inversa para obtener la dirección
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      String address = '';
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        // Construye la dirección en formato legible
        address =
            '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      }

      // Mueve el mapa a la ubicación del usuario
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation, 15.0),
      );

      // Actualiza el controlador de texto y agrega el marcador
      startController.text = address;
      addMarker(userLocation, true); // Agrega el marcador de inicio
    } catch (e) {
      print('Error al obtener la ubicación del usuario: $e');
      Get.snackbar('Error', 'Error al obtener la ubicación');
    }
  }
}

class MapScreen extends StatelessWidget {
  final TextEditingController endController;
  final String startAddress;
  final LatLng? startLatLng;

  MapScreen({
    required this.endController,
    required this.startAddress,
    required this.startLatLng,
  });

  @override
  Widget build(BuildContext context) {
    final MapController controller = Get.put(MapController(
      endControllerText: endController.text,
      startAddress: startAddress,
      startLatLng: startLatLng,
    ));

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Mapa
            Obx(() => GoogleMap(
                  onMapCreated: controller.onMapCreated,
                  markers: controller.markers.value,
                  polylines: controller.polylines.value,
                  initialCameraPosition: CameraPosition(
                    target: controller.center.value,
                    zoom: 15,
                  ),
                )),
            // Botón de regresar
            Positioned(
              top: 20.0,
              left: 10.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30.0,
                  ),
                  onPressed: () {
                    // Navega a la HomePage
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomePage(selectedIndex: 1)),
                    );
                  },
                ),
              ),
            ),
            // Campos de texto
            Positioned(
              top: 70.0,
              left: 10.0,
              right: 10.0,
              child: Obx(() {
                TextEditingController currentController =
                    controller.currentInputField.value == 'start'
                        ? controller.startController
                        : controller.endController;
                List<dynamic> currentPredictions =
                    controller.currentInputField.value == 'start'
                        ? controller.startPredictions
                        : controller.endPredictions;
                bool isFieldFocused =
                    controller.currentInputField.value == 'start'
                        ? controller.startFocusNode.hasFocus
                        : controller.endFocusNode.hasFocus;

                return Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10.0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Icon(
                                Icons.circle,
                                color: Colors.black,
                                size: 12.0,
                              ),
                              Container(
                                height: 40.0,
                                width: 2.0,
                                color: Colors.grey,
                              ),
                              Icon(
                                Icons.square,
                                color: Colors.black,
                                size: 12.0,
                              ),
                            ],
                          ),
                          SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                              children: [
                                TextField(
                                  controller: controller.startController,
                                  focusNode: controller.startFocusNode,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Dirección de inicio',
                                    hintStyle: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    controller.currentInputField.value =
                                        'start';
                                  },
                                ),
                                Divider(
                                  color: Colors.grey,
                                  thickness: 1.0,
                                ),
                                TextField(
                                  controller: controller.endController,
                                  focusNode: controller.endFocusNode,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '¿A dónde vas?',
                                    hintStyle: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    controller.currentInputField.value = 'end';
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Lista de predicciones
                    if (isFieldFocused &&
                        currentController.text.isNotEmpty &&
                        currentPredictions.isNotEmpty)
                      Container(
                        height: MediaQuery.of(context).size.height * 0.4,
                        margin: EdgeInsets.only(top: 8.0),
                        padding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              blurRadius: 10.0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          itemCount: currentPredictions.length,
                          itemBuilder: (context, index) {
                            var prediction = currentPredictions[index];
                            return GestureDetector(
                              onTap: () {
                                bool isStartPlace =
                                    controller.currentInputField.value ==
                                        'start';
                                controller.selectPlace(
                                    prediction['place_id'], isStartPlace);

                                if (isStartPlace) {
                                  controller.startController.text =
                                      prediction['description'];
                                } else {
                                  controller.endController.text =
                                      prediction['description'];
                                }

                                FocusScope.of(context).unfocus();
                              },
                              child: ListTile(
                                leading: Icon(
                                  Icons.location_on,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .iconlocation_on
                                      .withOpacity(0.8),
                                ),
                                title: Text(
                                  prediction['description'],
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    // Historial de búsqueda
                    if (isFieldFocused &&
                        currentController.text.isEmpty &&
                        controller.searchHistory.isNotEmpty)
                      Container(
                        height: MediaQuery.of(context).size.height * 0.3,
                        margin: EdgeInsets.only(top: 8.0),
                        padding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              blurRadius: 10.0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          itemCount: controller.searchHistory.length,
                          itemBuilder: (context, index) {
                            var historyItem = controller.searchHistory[index];
                            return GestureDetector(
                              onTap: () {
                                bool isStartPlace =
                                    controller.currentInputField.value ==
                                        'start';
                                controller.selectPlace(
                                    historyItem['place_id']!, isStartPlace);

                                if (isStartPlace) {
                                  controller.startController.text =
                                      historyItem['description']!;
                                } else {
                                  controller.endController.text =
                                      historyItem['description']!;
                                }

                                FocusScope.of(context).unfocus();
                              },
                              child: ListTile(
                                leading: Icon(
                                  Icons.history,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .iconhistory
                                      .withOpacity(0.8),
                                ),
                                title: Text(
                                  historyItem['description']!,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              }),
            ),
            // Botón de "Buscar conductor"
            Obx(() {
              return controller.isButtonVisible.value
                  ? Positioned(
                      bottom: 80.0,
                      left: 20.0,
                      right: 20.0,
                      child: ElevatedButton(
                        onPressed: () => controller.showRouteDetails(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.buttonColormap,
                          padding: EdgeInsets.symmetric(vertical: 18.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10.0),
                            Text(
                              controller.buttonText.value,
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox
                      .shrink(); // Renderiza un espacio vacío cuando el botón está oculto
            }),

            // Botón de ubicación del usuario
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              right: 25.0,
              child: FloatingActionButton(
                onPressed: controller.getUserLocation,
                child: Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
