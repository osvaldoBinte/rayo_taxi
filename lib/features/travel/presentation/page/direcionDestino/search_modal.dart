import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_place_details_and_move_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_place_predictions_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_search_history_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/save_search_history_usecase.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/addTravelController.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/mapa.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:get/get.dart';
class DestinoController extends GetxController {
  TextEditingController mainDestinoController = TextEditingController();
  FocusNode mainFocusNode = FocusNode();
  TextEditingController modalController = TextEditingController();
  FocusNode modalFocusNode = FocusNode();

  RxnString selectedPlaceId = RxnString();
  RxnString selectedDescription = RxnString();
  Rxn<LatLng> selectedLatLng = Rxn<LatLng>();
  RxString currentAddress = ''.obs;
  Rxn<LatLng> currentLatLng = Rxn<LatLng>();
  Rxn<Marker> selectedMarker = Rxn<Marker>();
  RxList<Map<String, String>> searchHistory = RxList<Map<String, String>>();
  RxList<dynamic> modalPredictions = RxList<dynamic>();
  RxList<Map<String, String>> modalSearchHistory =
      RxList<Map<String, String>>();
  RxString debugCoordinates = ''.obs;
 
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxBool isDebugMode = true.obs; // Para mostrar el punto exacto
  Timer? _debounceTimer;

  final markerId = const MarkerId('destination_marker');
    bool isMarkerMoving = false; 
  GoogleMapController? mapController;
  RxBool hasMapMoved = false.obs;
  final GetSearchHistoryUsecase getSearchHistoryUsecase;
  final SaveSearchHistoryUsecase saveSearchHistoryUsecase;
  final GetPlaceDetailsAndMoveUsecase getPlaceDetailsAndMoveUsecase;
  final GetPlacePredictionsUsecase getPlacePredictionsUsecase;

  DestinoController({
    required this.getSearchHistoryUsecase,
    required this.saveSearchHistoryUsecase,
    required this.getPlaceDetailsAndMoveUsecase,
    required this.getPlacePredictionsUsecase,
  });

  @override
  void onInit() {
    super.onInit();
    getUserAddress();
    loadSearchHistory();
    mainDestinoController.clear();
  }
  @override
  void onClose() {
    mainDestinoController.dispose();
    mainFocusNode.dispose();
    modalController.dispose();
    modalFocusNode.dispose();
    super.onClose();
  }
 void _initializeMarker(LatLng position) {
    markers.clear();  // Limpiar marcadores existentes
    markers.add(
      Marker(
        markerId: markerId,
        position: position,
        draggable: true,
        onDragStart: (_) {
          isMarkerMoving = true;
        },
        onDragEnd: (newPosition) {
          isMarkerMoving = false;
          updateMarkerPosition(newPosition);
        },
      ),
    );
  }

   void updateMarkerPosition(LatLng position) async {
    if (isMarkerMoving) return;  // No actualizar si el marcador se está moviendo

    try {
      // Actualizar posición del marcador
      markers.clear();
      markers.add(
        Marker(
          markerId: markerId,
          position: position,
          draggable: true,
          onDragStart: (_) {
            isMarkerMoving = true;
          },
          onDragEnd: (newPosition) {
            isMarkerMoving = false;
            updateMarkerPosition(newPosition);
          },
        ),
      );

      // Obtener dirección de la nueva posición
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '';
        
        if (place.thoroughfare?.isNotEmpty ?? false) {
          address += place.thoroughfare!;
        }
        if (place.subThoroughfare?.isNotEmpty ?? false) {
          address += ' ${place.subThoroughfare!}';
        }
        if (place.locality?.isNotEmpty ?? false) {
          address += ', ${place.locality!}';
        }
        if (place.subAdministrativeArea?.isNotEmpty ?? false) {
          address += ', ${place.subAdministrativeArea!}';
        }
        if (place.postalCode?.isNotEmpty ?? false) {
          address += ', ${place.postalCode!}';
        }

        address = address.replaceAll(RegExp(r'null,?\s*'), '')
                        .replaceAll(RegExp(r',\s*,'), ',')
                        .trim();

        selectedLatLng.value = position;
        selectedDescription.value = address;
        mainDestinoController.text = address;
      }
    } catch (e) {
      print('Error actualizando posición: $e');
      Get.snackbar('Error', 'No se pudo obtener la dirección');
    }
  }

  Future<void> loadSearchHistory() async {
    searchHistory.value = await getSearchHistoryUsecase.execute();
  }
  Widget buildCenterMarker() {
    return Center(
      child: Icon(
        Icons.location_on,
        size: 50,
        color: Colors.black,
      ),
    );
  } 

 void onCameraMove(CameraPosition position) {
    print('Centro exacto - Lat: ${position.target.latitude}, Lng: ${position.target.longitude}');
    
    // Actualizar el marcador en el centro exacto
    markers.clear();
   

    // Actualizar la dirección con debounce
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      updateAddressFromPosition(position.target);
    });
  }
  void onCameraIdle() {
    // No necesitamos hacer nada aquí
  }
  void getUserAddress() async {
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
        Get.snackbar('Error', 'Permisos de ubicación denegados permanentemente');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentLatLng.value = LatLng(position.latitude, position.longitude);

      if (mapController != null) {
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLatLng.value!,
              zoom: 16.0,
            ),
          ),
        );
        // Actualizar la dirección inicial
       // updateAddressFromPosition(currentLatLng.value!);
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al obtener la ubicación: $e');
    }
  }
 void updateAddressFromPosition(LatLng position) async {
    try {
            print('Centro exacto - Lat: ${position.latitude}, Lng: ${position.longitude}');
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '';
        print('Detalles del lugar:');
        print('Street: ${place.street}');
        print('Thoroughfare: ${place.thoroughfare}');
        print('SubThoroughfare: ${place.subThoroughfare}');
        print('Locality: ${place.locality}');
        print('SubLocality: ${place.subLocality}');
        print('PostalCode: ${place.postalCode}');
        
        if (place.thoroughfare?.isNotEmpty ?? false) {
          address += place.thoroughfare!;
        }
        if (place.subThoroughfare?.isNotEmpty ?? false) {
          address += ' ${place.subThoroughfare!}';
        }
        if (place.locality?.isNotEmpty ?? false) {
          address += ', ${place.locality!}';
        }
        if (place.subAdministrativeArea?.isNotEmpty ?? false) {
          address += ', ${place.subAdministrativeArea!}';
        }
        if (place.postalCode?.isNotEmpty ?? false) {
          address += ', ${place.postalCode!}';
        }

        address = address.replaceAll(RegExp(r'null,?\s*'), '')
                        .replaceAll(RegExp(r',\s*,'), ',')
                        .trim();
        print('Dirección final: $address');
        selectedLatLng.value = position;
        selectedDescription.value = address;
        mainDestinoController.text = address;
      }
    } catch (e) {
      print('Error actualizando dirección: $e');
      Get.snackbar('Error', 'No se pudo obtener la dirección');
    }
  }
  void navigateToMapScreen(BuildContext context) {
    if (Get.isRegistered<MapController>()) {
      final mapController = Get.find<MapController>();
      mapController.isTravelRequested.value = false;
      mapController.isModalOpen.value = false;
    }
    if (Get.isRegistered<NotificationController>()) {
      final notificationController = Get.find<NotificationController>();
    }
    if (!Get.isRegistered<ModalController>()) {
      Get.put(ModalController());
    }
    Get.find<NotificationController>().tripAccepted.value = false;
    Get.find<ModalController>().lottieUrl.value =
        'https://lottie.host/e44ab786-30a1-48ee-96eb-bb2e002f3ae8/NtzqQeAN8j.json';
    Get.find<ModalController>().modalText.value = 'Buscando chofer...';

    if (selectedLatLng.value != null && selectedDescription.value != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            endController: TextEditingController(text: selectedDescription.value),
            startAddress: currentAddress.value,
            startLatLng: currentLatLng.value,
            endLatLng: selectedLatLng.value,
          ),
        ),
      );
    } else {
      Get.snackbar('Error', 'Por favor, selecciona un destino primero');
    }
  }


  void onMarkerDragEnd(LatLng newPosition) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        newPosition.latitude,
        newPosition.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address =
            '${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';

        selectedLatLng.value = newPosition;
        selectedDescription.value = address;
        mainDestinoController.text = address;

        selectedMarker.value = Marker(
          markerId: MarkerId('selected_place'),
          position: newPosition,
          draggable: true,
          onDragEnd: (newPosition) => onMarkerDragEnd(newPosition),
        );

        await saveSearchHistoryUsecase.execute({
          'place_id': '',
          'description': address,
        });
        loadSearchHistory();
      } else {
        Get.snackbar('Error',
            'No se pudo obtener la dirección para la ubicación seleccionada');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al procesar la ubicación seleccionada');
    }
  }

  void selectPlace(String? placeId, String description, LatLng location) {
    selectedPlaceId.value = placeId;
    selectedDescription.value = description;
    selectedLatLng.value = location;
    mainDestinoController.text = description;

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: selectedLatLng.value!,
          zoom: 16.0,
        ),
      ),
    );
  }


  void handlePlaceSelection(String placeId, String description) async {
    try {
      await getPlaceDetailsAndMoveUsecase.execute(
        placeId,
        (LatLng location) {
          selectPlace(placeId, description, location);
        },
        (LatLng location) {},
      );

      await saveSearchHistoryUsecase.execute({
        'place_id': placeId,
        'description': description,
      });
      loadSearchHistory();
    } catch (e) {
      Get.snackbar('Error', 'Error al seleccionar el lugar');
    }
  }

  void showSearchModal(BuildContext context) {
    modalController.clear();
    modalPredictions.clear();
    modalSearchHistory.assignAll(searchHistory);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          height: 5,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Fija tu destino',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: modalController,
                        focusNode: modalFocusNode,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '¿A dónde quieres ir?',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: onModalTextChanged,
                      ),
                      SizedBox(height: 16),
                      Obx(() {
                        if (modalController.text.isEmpty &&
                            modalSearchHistory.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Historial de Búsquedas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: modalSearchHistory.length,
                                itemBuilder: (context, index) {
                                  Map<String, String> historyItem =
                                      modalSearchHistory[index];
                                  return ListTile(
                                    onTap: () {
                                      String placeId = historyItem['place_id']!;
                                      String description =
                                          historyItem['description']!;
                                      handleModalPlaceSelection(
                                          placeId, description, context);
                                    },
                                    leading: Icon(Icons.history),
                                    title: Text(historyItem['description']!),
                                  );
                                },
                              ),
                            ],
                          );
                        } else if (modalController.text.isNotEmpty &&
                            modalPredictions.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: modalPredictions.length,
                                itemBuilder: (context, index) {
                                  var prediction = modalPredictions[index];
                                  return ListTile(
                                    onTap: () {
                                      String placeId = prediction['place_id'];
                                      String description =
                                          prediction['description'];
                                      handleModalPlaceSelection(
                                          placeId, description, context);
                                    },
                                    leading: Icon(Icons.location_on),
                                    title: Text(prediction['description']),
                                  );
                                },
                              ),
                            ],
                          );
                        } else {
                          return Container();
                        }
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void onModalTextChanged(String input) async {
    if (input.isEmpty) {
      modalPredictions.clear();
      modalSearchHistory.assignAll(searchHistory);
    } else {
      try {
        List<dynamic> predictions =
            await getPlacePredictionsUsecase.execute(input);
        modalPredictions.assignAll(predictions);
        modalSearchHistory.clear();
      } catch (e) {
        Get.snackbar('Error', 'Error al obtener predicciones');
        modalPredictions.clear();
      }
    }
  }

  void handleModalPlaceSelection(
      String placeId, String description, BuildContext context) async {
    try {
      List<Location> locations = await locationFromAddress(description);
      if (locations.isNotEmpty) {
        LatLng selectedLocation =
            LatLng(locations.first.latitude, locations.first.longitude);
        selectPlace(placeId, description, selectedLocation);
        Navigator.pop(context);
      } else {
        Get.snackbar('Error', 'No se pudo obtener la ubicación');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al obtener la ubicación');
    }
  }
}