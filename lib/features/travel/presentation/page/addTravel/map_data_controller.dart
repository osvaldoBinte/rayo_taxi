import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
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
}
