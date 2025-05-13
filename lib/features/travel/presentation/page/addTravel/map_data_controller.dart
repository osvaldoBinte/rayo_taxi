import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rayo_taxi/common/constants/constants.dart';
import 'package:rayo_taxi/features/travel/data/datasources/mapa_local_data_source.dart';
import 'package:rayo_taxi/features/travel/domain/entities/getcosttraveEntitie/getcosttravel_entitie.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/calculate_distance_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/decode_polyline_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_duration_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_encoded_points_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_place_details_and_move_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_place_predictions_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_route_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/get_search_history_usecase.dart';
import 'package:rayo_taxi/features/travel/domain/usecases/save_search_history_usecase.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
class MapDataController {
  final TravelLocalDataSource _dataSource = TravelLocalDataSourceImp();
  final GetSearchHistoryUsecase getSearchHistoryUsecase;
  final SaveSearchHistoryUsecase saveSearchHistoryUsecase;
  final GetPlaceDetailsAndMoveUsecase getPlaceDetailsAndMoveUsecase;
  final GetPlacePredictionsUsecase getPlacePredictionsUsecase;
  final CalculateDistanceUsecase? calculateDistanceUsecase;
  final GetRouteUsecase? getRouteUsecase;
  final GetEncodedPointsUsecase? getEncodedPointsUsecase;
  final DecodePolylineUsecase? decodePolylineUsecase;
  final GetDurationUsecase? getDurationUsecase;

  MapDataController({
    required this.getSearchHistoryUsecase,
    required this.saveSearchHistoryUsecase,
    required this.getPlaceDetailsAndMoveUsecase,
    required this.getPlacePredictionsUsecase,
    required this.calculateDistanceUsecase,
    required this.getRouteUsecase,
    required this.getEncodedPointsUsecase,
    required this.decodePolylineUsecase,
    required this.getDurationUsecase,

  });
       String _apiKey = AppConstants.apikey;

  Future<List<dynamic>> getPlacePredictions(String input,
      {LatLng? location}) async {
    return await getPlacePredictionsUsecase.execute(input, location: location);
  }

  Future<void> getPlaceDetailsAndMove(
    String placeId,
    Function(LatLng) onCameraMove,
    Function(LatLng) onMarkerAdd,
  ) async {
    await getPlaceDetailsAndMoveUsecase.execute(
        placeId, onCameraMove, onMarkerAdd);
  }

  Future<void> saveSearchHistory(Map<String, String> searchData) async {
    await saveSearchHistoryUsecase.execute(searchData);
  }

  Future<List<Map<String, String>>> getSearchHistory() async {
    return await getSearchHistoryUsecase.execute();
  }

  double calculateDistance(LatLng start, LatLng end) {
    return calculateDistanceUsecase!.execute(start, end);
  }

  double getDuration() {
    return getDurationUsecase!.execute();
  }

  Future<void> getRoute(LatLng start, LatLng end) async {
    await getRouteUsecase?.execute(start, end);
  }

  Future<String> getEncodedPoints() async {
    return await getEncodedPointsUsecase!.execute();
  }

  List<LatLng> decodePolyline(String encodedPoints) {
    return decodePolylineUsecase!.execute(encodedPoints);
  }

  Future<GetcosttravelEntitie> getCostTravel(
      double kilometers, double duration) async {
    return GetcosttravelEntitie(
      kilometers: kilometers,
      duration: duration,
    );
  }

void showLocationPreview(LatLng location, String title) {
  final colorScheme = Theme.of(Get.context!).colorScheme;
  final String streetViewUrl = 'https://maps.googleapis.com/maps/api/streetview?'
    'size=600x400'
    '&location=${location.latitude},${location.longitude}'
    '&fov=90'
    '&heading=70'
    '&pitch=0'
    '&key=${_apiKey}';

  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: Get.width * 0.85,
        decoration: BoxDecoration(
          color: colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 8, 16),
              decoration: BoxDecoration(
                color: colorScheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.textButton,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.CurvedNavigationIcono2),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Contenedor de imagen
            Container(
              height: Get.height * 0.3,
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.loaderbaseColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      streetViewUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colorScheme.loaderbaseColor,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.loader),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.loaderbaseColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: colorScheme.icongrey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Vista no disponible',
                                style: TextStyle(
                                  color: colorScheme.snackBartext2,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Overlay con coordenadas
                  
                  ],
                ),
              ),
            ),
            // Botones de acción
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                 
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.buttonColormap,
                      foregroundColor: colorScheme.textButton,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierColor: Colors.black54,
  );
}

}
