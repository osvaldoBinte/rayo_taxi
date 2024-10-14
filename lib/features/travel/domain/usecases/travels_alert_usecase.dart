import '../../data/models/travel_alert_model.dart';
import '../repositories/travel_repository.dart';

class TravelsAlertUsecase {
  final TravelRepository travelRepository;
  TravelsAlertUsecase({required this.travelRepository});
  Future<List<TravelAlertModel>> execute(bool connection) async {
    return await travelRepository.getalltravel(connection);
  }
}
