import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_place_details_and_move_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_place_predictions_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_search_history_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/save_search_history_usecase.dart';
import 'package:rayo_taxi/features/travel/presentation/page/mapa.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:get/get.dart';

class DestinoController extends GetxController {
  // Controladores y FocusNodes
  TextEditingController mainDestinoController = TextEditingController();
  FocusNode mainFocusNode = FocusNode();
  TextEditingController modalController = TextEditingController();
  FocusNode modalFocusNode = FocusNode();

  // Variables observables
  RxnString selectedPlaceId = RxnString();
  RxnString selectedDescription = RxnString();
  Rxn<LatLng> selectedLatLng = Rxn<LatLng>();
  RxString currentAddress = ''.obs;
  Rxn<LatLng> currentLatLng = Rxn<LatLng>();
  Rxn<Marker> selectedMarker = Rxn<Marker>();
  RxList<Map<String, String>> searchHistory = RxList<Map<String, String>>();
  RxList<dynamic> modalPredictions = RxList<dynamic>();
  RxList<Map<String, String>> modalSearchHistory = RxList<Map<String, String>>();

  GoogleMapController? mapController;

 final GetSearchHistoryUsecase  getSearchHistoryUsecase;
 final SaveSearchHistoryUsecase saveSearchHistoryUsecase;
 final GetPlaceDetailsAndMoveUsecase getPlaceDetailsAndMoveUsecase;
 final GetPlacePredictionsUsecase getPlacePredictionsUsecase;
 DestinoController({required this.getSearchHistoryUsecase, required this.saveSearchHistoryUsecase,required this.getPlaceDetailsAndMoveUsecase,required this.getPlacePredictionsUsecase});
  @override
  void onInit() {
    super.onInit();
    getUserAddress();
    loadSearchHistory();
  }

  @override
  void onClose() {
    mainDestinoController.dispose();
    mainFocusNode.dispose();
    modalController.dispose();
    modalFocusNode.dispose();
    super.onClose();
  }

  Future<void> loadSearchHistory() async {
    searchHistory.value = await getSearchHistoryUsecase.execute();
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

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address =
            '${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';
        currentAddress.value = address;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al obtener la ubicación');
    }
  }

  void navigateToMapScreen(BuildContext context) {
    if (selectedLatLng.value != null && selectedDescription.value != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            endController:
                TextEditingController(text: selectedDescription.value),
            startAddress: currentAddress.value,
            startLatLng: currentLatLng.value,
            // endLatLng: selectedLatLng.value,
          ),
        ),
      );
    } else {
      Get.snackbar('Error', 'Por favor, selecciona un destino primero');
    }
  }

  void selectPlace(String placeId, String description, LatLng location) {
    selectedPlaceId.value = placeId;
    selectedDescription.value = description;
    selectedLatLng.value = location;
    mainDestinoController.text = description;
    selectedMarker.value = Marker(
      markerId: MarkerId('selected_place'),
      position: selectedLatLng.value!,
    );

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
        (LatLng location) {
          // Lógica adicional si es necesario
        },
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                            color: Colors.grey[300],
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
                                      String placeId =
                                          historyItem['place_id']!;
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

class DestinoPage extends StatelessWidget {
  //final DestinoController controller = Get.put(DestinoController());
  final DestinoController controller = Get.find<DestinoController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() => GoogleMap(
                onMapCreated: (GoogleMapController mapController) {
                  controller.mapController = mapController;
                },
                initialCameraPosition: CameraPosition(
                  target: controller.currentLatLng.value ??
                      LatLng(20.6596988, -103.3496092),
                  zoom: 15,
                ),
                markers: controller.selectedMarker.value != null
                    ? {controller.selectedMarker.value!}
                    : {},
                onCameraMove: (CameraPosition position) {
                  controller.currentLatLng.value = position.target;
                },
              )),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fija tu destino',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: controller.mainDestinoController,
                    focusNode: controller.mainFocusNode,
                    onTap: () => controller.showSearchModal(context),
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
                    readOnly: true,
                  ),
                  SizedBox(height: 16),
                  Obx(() {
                    bool isEnabled = controller.selectedDescription.value != null &&
                        controller.selectedDescription.value!.isNotEmpty;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isEnabled
                            ? () => controller.navigateToMapScreen(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isEnabled ? Colors.black : Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          'Confirmar destino',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 75),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
