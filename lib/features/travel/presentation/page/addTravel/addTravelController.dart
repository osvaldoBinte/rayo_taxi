import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/home_page.dart';
import 'package:rayo_taxi/features/travel/data/datasources/travel_local_data_source.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/domain/entities/getcosttraveEntitie/getcosttravel_entitie.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/entities/travel.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/CustomImage.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/MapLocationSelector/MapLocationSelectorModal.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/map_data_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/current_travel/current_travel_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/Taxi_Info_card.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/calculate_price.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../AuthS/connectivity_service.dart';
import '../../Travelgetx/TravelAlert/travel_alert_getx.dart';

class MapController extends GetxController {
  final String endControllerText;
  final String startAddress;
  final LatLng? startLatLng;
  final LatLng? endLatLng;
  final String endAddress;

  MapController({
    required this.endControllerText,
    required this.startAddress,
    required this.startLatLng,
    this.endLatLng,
    this.endAddress = '',
    required this.travelList,              // Add this line
  });

  late GoogleMapController mapController;
  final TravelGetx travelGetx = Get.find<TravelGetx>();
  final DeleteTravelGetx deleteTravelGetx = Get.find<DeleteTravelGetx>();
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();
  final TravelsAlertGetx travelAlertGetx = Get.find<TravelsAlertGetx>();
  final CurrentTravelGetx currentTravelGetx = Get.find<CurrentTravelGetx>();
  ValueNotifier<double> travelDuration = ValueNotifier(0.0);
  RxBool canShowDirectionModal = true.obs;
  RxBool isTravelRequested = false.obs;
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
  final MapDataController _mapDataController = Get.find<MapDataController>();

  NotificationLocalDataSource travelLocal = NotificationLocalDataSourceImp();
  RxString travelPrice = ''.obs;

  final NotificationController notificationController =
      Get.find<NotificationController>();
  final ModalController modalController = Get.find<ModalController>();
  late ConnectivityService connectivityService;
  RxString startAddressText = ''.obs;
  RxString endAddressText = ''.obs;
  RxBool isModalOpen = false.obs;

  FocusNode startFocusNode = FocusNode();
  FocusNode endFocusNode = FocusNode();
  RxString currentInputField = 'start'.obs;
  Completer<GoogleMapController> controllerCompleter = Completer();

  RxList<Map<String, String>> searchHistory = <Map<String, String>>[].obs;
  late CurrentTravelController controller;   // Add this line

  RxString lottieUrl =
      'https://lottie.host/a811be92-b006-48ce-ad3e-c20bfffc3d7e/NzmrksnYZW.json'
          .obs;
  RxString modalText = 'Buscando chofer...'.obs;
  final List<TravelAlertModel> travelList;  // Add this line

  @override
  void onInit() {
    super.onInit();
    connectivityService = ConnectivityService();
    endController.text = endAddress.isNotEmpty ? endAddress : endControllerText;
    startController.text = startAddress;
  controller = Get.put(CurrentTravelController(travelList: travelList));  // Add this line

    startController.addListener(() {
      startAddressText.value = startController.text;
    });

    endController.addListener(() {
      endAddressText.value = endController.text;
    });
    if (startLatLng != null) {
      startLocation.value = startLatLng;
    }

    if (endLatLng != null) {
      endLocation.value = endLatLng;
    }
    if (startController.text.isNotEmpty) {
      searchAndSelectPlace(startController.text, isStartPlace: true);
    }

    if (endController.text.isNotEmpty) {
      searchAndSelectPlace(endController.text, isStartPlace: false);
    }

    startController.addListener(() {
      if (currentInputField.value == 'start') {
        searchPlace(startController.text, isStartPlace: true);
      }
    });

    endController.addListener(() {
      if (currentInputField.value == 'end') {
        searchPlace(endController.text, isStartPlace: false);
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

    startPredictions.clear();
    endPredictions.clear();

    loadSearchHistory();
  }

  static MapController init(
    String endText,
    String startAddr,
    LatLng? startPos, {
    LatLng? endLatLng,
    String endAddress = '',
  }) {
    if (Get.isRegistered<MapController>()) {
      final controller = Get.find<MapController>();
      controller.cleanupController();
      Get.delete<MapController>();
    }

    return Get.put(MapController(
      endControllerText: endText,
      startAddress: startAddr,
      startLatLng: startPos,
      endLatLng: endLatLng,
      endAddress: endAddress, travelList: [],
    ));
  }

  void reinitialize() {
    startController = TextEditingController(text: startAddress);
    endController = TextEditingController(text: endControllerText);
    startFocusNode = FocusNode();
    endFocusNode = FocusNode();

    startController.addListener(() {
      startAddressText.value = startController.text;
      if (currentInputField.value == 'start') {
        searchPlace(startController.text, isStartPlace: true);
      }
    });

    endController.addListener(() {
      endAddressText.value = endController.text;
      if (currentInputField.value == 'end') {
        searchPlace(endController.text, isStartPlace: false);
      }
    });

    // Reset observable values
    startPredictions.clear();
    endPredictions.clear();
    markers.clear();
    polylines.clear();

    loadSearchHistory();
  }

  Future<void> fetchTravelCost() async {
    if (startLocation.value != null && endLocation.value != null) {
      double distance = _mapDataController.calculateDistance(
          startLocation.value!, endLocation.value!);
      double duration = _mapDataController.getDuration();
      print('=====duration fetchTravelCost $duration distance $distance');

      try {
        final getCostTravelEntity = GetcosttravelEntitie(
          kilometers: distance,
          duration: duration,
        );

        final response = await travelLocal.getcosttravel(getCostTravelEntity);

        final formattedPrice = (response.data ?? 0.0).toStringAsFixed(3);
        travelPrice.value = '\$$formattedPrice MXN';

        travelDuration.value = duration;
      } catch (e) {
        print('Error al obtener el costo del viaje: $e');
        travelPrice.value = 'Error';
        travelDuration.value = 0;
      }
    }
  }

// Helper method to extract coordinates from address string
  LatLng? extractCoordinatesFromAddress(String address) {
    try {
      // Look for coordinates in parentheses at the end of the string
      final RegExp coordRegex = RegExp(r'\(([-\d.]+),\s*([-\d.]+)\)$');
      final match = coordRegex.firstMatch(address);

      if (match != null) {
        final lat = double.parse(match.group(1)!);
        final lng = double.parse(match.group(2)!);
        return LatLng(lat, lng);
      }
    } catch (e) {
      print('Error extracting coordinates: $e');
    }
    return null;
  }

// Helper method to format address with coordinates
  String formatAddressWithCoordinates(String address, LatLng location) {
    String coordString =
        '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
    return address.isNotEmpty ? '$address\n($coordString)' : coordString;
  }

  void showLocationPicker(BuildContext context, bool isStartPlace) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MapLocationSelectorModal(
        isStartLocation: isStartPlace,
        initialLocation: isStartPlace ? startLocation.value : endLocation.value,
        onLocationSelected: (address, location) async {
          if (isStartPlace) {
            startController.text = address;
            startLocation.value = location;
          } else {
            endController.text = address;
            endLocation.value = location;
          }
          addMarker(location, isStartPlace);

          await mapController.animateCamera(
            CameraUpdate.newLatLngZoom(location, 15.0),
          );

          if (startLocation.value != null && endLocation.value != null) {
            traceRoute();
          }
        },
      ),
    );
  }

  Future<void> loadSearchHistory() async {
    searchHistory.value = await _mapDataController.getSearchHistory();
  }

  void updateMarkerIcons() async {
    if (startLocation.value != null) {
      markers.removeWhere((m) => m.markerId.value == 'start');
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('start'),
          position: startLocation.value!,
          infoWindow: gmaps.InfoWindow(title: 'Inicio'),
          draggable: true,
          icon: await gmaps.BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(48, 48)),
            'assets/images/mapa/marker.gif',
          ),
          onDragEnd: (newPosition) => onMarkerDragEnd(newPosition, true),
        ),
      );
    }

    if (endLocation.value != null) {
      markers.removeWhere((m) => m.markerId.value == 'destination');
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('destination'),
          position: endLocation.value!,
          infoWindow: gmaps.InfoWindow(title: 'Destino'),
          draggable: true,
          icon: await gmaps.BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(48, 48)),
            'assets/images/mapa/marker.gif',
          ),
          onDragEnd: (newPosition) => onMarkerDragEnd(newPosition, false),
        ),
      );
    }
  }

  void cleanupController() {
    startFocusNode.dispose();
    endFocusNode.dispose();
    startController.dispose();
    endController.dispose();
    mapController.dispose();
  }

  @override
  void onClose() {
    cleanupController();
    super.onClose();
  }

  void onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    controllerCompleter.complete(controller);

    if (startLatLng != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(startLatLng!, 15.0),
      );

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            startLatLng!.latitude, startLatLng!.longitude);

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String address =
              '${place.street}, ${place.locality}, ${place.country}';
          startController.text = address;
          startLocation.value = startLatLng;
        }
      } catch (e) {
        print('Error obteniendo dirección: $e');
      }

      addMarker(startLatLng!, true);
    }
  }

  void addMarker(LatLng latLng, bool isStartPlace) async {
    if (isStartPlace) {
      markers.removeWhere((m) => m.markerId.value == 'start');
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('start'),
          position: latLng,
          infoWindow: gmaps.InfoWindow(title: 'Inicio'),
          draggable: true,
          icon: await gmaps.BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(10, 10)),
            'assets/images/mapa/origen.png',
          ),
          onDragEnd: (newPosition) => onMarkerDragEnd(newPosition, true),
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
          draggable: true,
          icon: await gmaps.BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(10, 10)),
            'assets/images/mapa/destino.png',
          ),
          onDragEnd: (newPosition) => onMarkerDragEnd(newPosition, false),
        ),
      );
      endLocation.value = latLng;
    }

    if (startLocation.value != null && endLocation.value != null) {
      traceRoute();
    }
  }

  void onMarkerDragEnd(LatLng newPosition, bool isStartPlace) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          newPosition.latitude, newPosition.longitude);
      String address = '';
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        address =
            '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      }

      if (isStartPlace) {
        startController.text = address;
        startLocation.value = newPosition;
      } else {
        endController.text = address;
        endLocation.value = newPosition;
      }

      addMarker(newPosition, isStartPlace);

      if (startLocation.value != null && endLocation.value != null) {
        traceRoute();
      }
    } catch (e) {
      print('Error al realizar geocodificación inversa: $e');
      //  Get.snackbar('Error', 'No se pudo obtener la dirección');
    }
  }

  void searchAndSelectPlace(String placeName,
      {required bool isStartPlace}) async {
    if (placeName.isEmpty) return;

    List<dynamic> predictions =
        await _mapDataController.getPlacePredictions(placeName);

    if (predictions.isNotEmpty) {
      String placeId = predictions.first['place_id'];
      selectPlace(placeId, isStartPlace);

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
        await _mapDataController.getRoute(
            startLocation.value!, endLocation.value!);
        String encodedPoints = await _mapDataController.getEncodedPoints();
        List<LatLng> polylineCoordinates =
            _mapDataController.decodePolyline(encodedPoints);

        polylines.clear();
        polylines.add(Polyline(
          polylineId: PolylineId('route'),
          points: polylineCoordinates,
          color: Colors.black,
          width: 5,
        ));

        await fetchTravelCost();
      } catch (e) {
        print('Error al trazar la ruta: $e');
      }
    }
  }

  void showRouteDetails(BuildContext context) async {
    if (isModalOpen.value) {
      return;
    }

    Get.dialog(
      Container(
        color: Theme.of(context).colorScheme.loader.withOpacity(0.5),
        child: Center(
          child: SpinKitFadingCube(
            color: Theme.of(context).colorScheme.loader,
            size: 50.0,
          ),
        ),
      ),
      barrierDismissible: false,
    );

    RxBool isCancelling = false.obs;

    try {
      if (startLocation.value != null && endLocation.value != null) {
        if (!isTravelRequested.value &&
            !notificationController.tripAccepted.value) {
          isTravelRequested.value = true;
          isModalOpen.value = true;
          canShowDirectionModal.value = false;

          double distance = _mapDataController.calculateDistance(
              startLocation.value!, endLocation.value!);
          double duration = _mapDataController.getDuration();
          List<Placemark> placemarks = await placemarkFromCoordinates(
            startLocation.value!.latitude,
            startLocation.value!.longitude,
          );
          String state = '';
          String municipality = '';
          if (placemarks.isNotEmpty) {
            Placemark placemark = placemarks.first;
            state = placemark.administrativeArea ?? '';
            municipality = placemark.locality ?? '';
          }

          final post = Travel(
            start_longitude: startLocation.value!.longitude,
            start_latitude: startLocation.value!.latitude,
            end_longitude: endLocation.value!.longitude,
            end_latitude: endLocation.value!.latitude,
            kilometers: distance.toStringAsFixed(2),
            duration: duration.toStringAsFixed(2),
            state: state,
            municipality: municipality,
          );

          await travelGetx.poshTravel(CreateTravelEvent(post));
          await currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
        }
        await currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());

        Get.back();

        Get.bottomSheet(
          WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: FractionallySizedBox(
              heightFactor: 0.75,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox.expand(
                  child: Container(
                    color: Theme.of(context).colorScheme.card,
                    padding: EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[ GetBuilder<ModalController>(
        init: ModalController(),
        builder: (modalController) => CustomLottieWidget(
          controller: modalController,
          onError: () {
            // Manejar el error después de que el widget esté construido
            WidgetsBinding.instance.addPostFrameCallback((_) {
              modalController.isLottieError.value = true;
            });
          },
        ),
      ),
  SizedBox(height: 20),

                          SizedBox(height: 20),
                          Obx(() {
                            final state = currentTravelGetx.state.value;
                            if (state is TravelAlertLoaded) {
                              final travel = state.travel.first;
                              return Obx(() {
  final state = currentTravelGetx.state.value;
  if (state is TravelAlertLoaded) {
    final travel = state.travel.first;
    return travel.id_status == 3 || travel.id_status == 4
      ? TaxiInfoCard(
          isDriverApproaching: true,
          driverLocation: controller.driverLocation.value,
          startLocation: controller.startLocation.value,
          endLocation: controller.endLocation.value,
          currentStatus: controller.idStatus.value,
          travelDuration: controller.travelDuration,
          travelPrice: controller.travelPrice,
        )
      : CalculatePrice(
          travelDuration: travelDuration,
          travelPrice: travelPrice,
          fixedPrice: '\$${travel.cost} MXN',
          useFixedPrice: true,
        );
  }
  return const SizedBox.shrink();
});
                            } else if (state is TravelAlertLoading) {
                              return CircularProgressIndicator();
                            } else if (state is TravelAlertFailure) {
                              return Text(
                                'Calculando...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          }),
                          SizedBox(height: 20),
                          Obx(() {
                            return notificationController.tripAccepted.value
                                ? SizedBox.shrink()
                                : ElevatedButton(
                                    onPressed: isCancelling.value
                                        ? null
                                        : () async {
                                            if (isCancelling.value) return;
                                            isCancelling.value = true;
                                            canShowDirectionModal.value = true;
                                            try {
                                              int? savedTravelId =
                                                  await getSavedTravelId();
                                              if (savedTravelId != null) {
                                                await deleteTravelGetx
                                                    .deleteTravel(
                                                        DeleteTravelEvent(
                                                            savedTravelId
                                                                .toString()));
                                                isTravelRequested.value = false;
                                                Get.back();
                                              } else {
                                                CustomSnackBar.showError(
                                                  'Error',
                                                  'No se encontró un ID de viaje válido',
                                                );
                                              }
                                            } catch (e) {
                                              CustomSnackBar.showError(
                                                'Error',
                                                'Error al cancelar el viaje',
                                              );
                                            } finally {
                                              isCancelling.value = false;
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .buttonColor,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .buttontext,
                                      disabledBackgroundColor: Theme.of(context)
                                          .colorScheme
                                          .buttonColor
                                          .withOpacity(0.5),
                                    ),
                                    child: Text(isCancelling.value
                                        ? 'Cancelando...'
                                        : 'Cancelar viaje'),
                                  );
                          })
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        ).whenComplete(() {
          isModalOpen.value = false;
        });
      } else {
        Get.back();

        CustomSnackBar.showError(
          'Error',
          'Por favor, ingresa la dirección de inicio y destino.',
        );
      }
    } catch (e) {
      Get.back();

      CustomSnackBar.showError(
        'Error',
        'Ocurrió un error al procesar tu solicitud.',
      );
    }
  }

  Future<void> searchPlace(String input, {required bool isStartPlace}) async {
    if (input.isEmpty) {
      if (isStartPlace)
        startPredictions.clear();
      else
        endPredictions.clear();
      return;
    }

    LatLng? locationBias = isStartPlace ? startLatLng : null;
    List<dynamic> predictions = await _mapDataController.getPlacePredictions(
      input,
      location: locationBias,
    );

    if (isStartPlace)
      startPredictions.assignAll(predictions);
    else
      endPredictions.assignAll(predictions);
  }

  void swapLocations() {
    String tempText = startController.text;
    startController.text = endController.text;
    endController.text = tempText;

    LatLng? tempLocation = startLocation.value;
    startLocation.value = endLocation.value;
    endLocation.value = tempLocation;

    if (startLocation.value != null && endLocation.value != null) {
      markers.clear();
      addMarker(startLocation.value!, true);
      addMarker(endLocation.value!, false);
      traceRoute();
    }
  }

  void selectPlace(String placeId, bool isStartPlace) async {
    await _mapDataController.getPlaceDetailsAndMove(
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

    await _mapDataController.saveSearchHistory({
      'place_id': placeId,
      'description': isStartPlace ? startController.text : endController.text,
    });
    loadSearchHistory();
  }

  void getUserLocation() async {
    try {
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

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      String address = '';
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        address =
            '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      }

      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation, 15.0),
      );

      startController.text = address;
      addMarker(userLocation, true);
    } catch (e) {
      print('Error al obtener la ubicación del usuario: $e');
      //Get.snackbar('Error', 'Error al obtener la ubicación');
    }
  }

  void showDirectionModal(BuildContext context, MapController controller) {
    if (!canShowDirectionModal.value) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (context, scrollController) {
            return Obx(() {
              TextEditingController currentController =
                  (controller.currentInputField.value == 'start')
                      ? controller.startController
                      : controller.endController;

              List<dynamic> currentPredictions =
                  (controller.currentInputField.value == 'start')
                      ? controller.startPredictions
                      : controller.endPredictions;

              bool isFieldFocused =
                  (controller.currentInputField.value == 'start')
                      ? controller.startFocusNode.hasFocus
                      : controller.endFocusNode.hasFocus;

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 5,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Elegir Direcciones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
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
                                      hintText: 'Dirección de inicio',
                                      border: InputBorder.none,
                                    ),
                                    onTap: () {
                                      controller.currentInputField.value =
                                          'start';
                                    },
                                    onChanged: (value) {
                                      controller.currentInputField.value =
                                          'start';
                                    },
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 8.0),
                                    height: 1.0,
                                    color: Colors.grey,
                                  ),
                                  TextField(
                                    controller: controller.endController,
                                    focusNode: controller.endFocusNode,
                                    decoration: InputDecoration(
                                      hintText: '¿A dónde vas?',
                                      border: InputBorder.none,
                                    ),
                                    onTap: () {
                                      controller.currentInputField.value =
                                          'end';
                                    },
                                    onChanged: (value) {
                                      controller.currentInputField.value =
                                          'end';
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      if (isFieldFocused &&
                          currentController.text.isNotEmpty &&
                          currentPredictions.isNotEmpty)
                        Container(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: currentPredictions.length,
                            itemBuilder: (context, index) {
                              var prediction = currentPredictions[index];
                              return ListTile(
                                leading: Image.asset(
                                  controller.currentInputField.value == 'start'
                                      ? 'assets/images/mapa/marker-inicio.png'
                                      : 'assets/images/mapa/marker-destino.png',
                                  width: 24,
                                  height: 24,
                                ),
                                title: Text(prediction['description']),
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
                              );
                            },
                          ),
                        ),
                      if (isFieldFocused &&
                          currentController.text.isEmpty &&
                          controller.searchHistory.isNotEmpty)
                        Container(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: controller.searchHistory.length,
                            itemBuilder: (context, index) {
                              var historyItem = controller.searchHistory[index];
                              return ListTile(
                                leading:
                                    Icon(Icons.history, color: Colors.black87),
                                title: Text(historyItem['description']!),
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
                              );
                            },
                          ),
                        ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => controller.showLocationPicker(context,
                            controller.currentInputField.value == 'start'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              controller.currentInputField.value == 'start'
                                  ? 'assets/images/mapa/marker-inicio.png'
                                  : 'assets/images/mapa/marker-destino.png',
                              width: 24,
                              height: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Establece tu ubicación en el mapa",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .buttonColormap,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            });
          },
        );
      },
    );
  }
}
