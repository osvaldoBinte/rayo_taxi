import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/common/routes/router.dart';
import 'package:rayo_taxi/common/settings/app_lifecycle_handler.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/common/theme/App_Theme.dart';
import 'package:rayo_taxi/main.dart';
import 'package:rayo_taxi/common/notification_service.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/LifeCycleController.dart';
import 'package:rayo_taxi/features/travel/presentation/page/addTravel/map_data_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/page/direcionDestino/search_modal.dart';
import 'package:rayo_taxi/features/travel/presentation/page/ratetrip/rate_trip_controller.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/calculateAge/calculateAge_getx.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/loginGoogle/loginGoogle_getx.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/update/Update_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/add_client/get_genders_controller/get_genders_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/recoveryPassword/create_recovery_code_controller.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/Device/id_device_get.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/Device/renew_token.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelById/travel_by_id_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelWithTariff/travelWithTariff_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/offerNegotiation/offerNegotiation_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/rejectTravelOffer/rejectTravelOffer_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/removeDataAccount/removeDataAccount_getx.dart';

import 'package:rayo_taxi/features/travel/presentation/getx/delete/delete_travel_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/travel/travel_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/add_client/addclient/client_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/login/loginclient_getx.dart';
import 'package:rayo_taxi/features/client/presentation/getxs/get/get_client_getx.dart';
import 'package:rayo_taxi/usecase_config.dart';
UsecaseConfig usecaseConfig = UsecaseConfig();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
   

    return AppLifecycleHandler(
      child: GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      supportedLocales: [
        const Locale('es', 'ES'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
     initialBinding: BindingsBuilder(() async {
          Get.put(NavigationService());
            Get.put(RenewTokenGetx(renewTokenUsecase: usecaseConfig.renewTokenUsecase!));
  Get.put(LifeCycleController()); 
  Get.put(RateTripController(qualificationUsecase: usecaseConfig.qualificationUsecase!));
  Get.put(ClientGetx(createClientUsecase: usecaseConfig.createClientUsecase!));
  Get.put(
      LoginclientGetx(loginClientUsecase: usecaseConfig.loginClientUsecase!, loginGoogleUsecase: usecaseConfig.loginGoogleUsecase!, idDeviceUsecase: usecaseConfig.idDeviceUsecase!,));
  Get.put(GetClientGetx(
      getClientUsecase: usecaseConfig.getClientUsecase!,
      connectivityService: connectivityService));
  Get.put(UpdateGetx(updateClientUsecase: usecaseConfig.updateClientUsecase!));
  Get.put(TravelGetx(poshTravelUsecase: usecaseConfig.poshTravelUsecase!));
  Get.put(TravelsAlertGetx(
      travelsAlertUsecase: usecaseConfig.travelsAlertUsecase!,
      connectivityService: connectivityService));
  Get.put(CurrentTravelGetx(
      currentTravelUsecase: usecaseConfig.currentTravelUsecase!,
      connectivityService: connectivityService));
  Get.put(CalculateAgeGetx(
      calculateAgeUsecase: usecaseConfig.calculateAgeUsecase!));
  Get.put(DeleteTravelGetx(
      deleteTravelUsecase: usecaseConfig.deleteTravelUsecase!,
      connectivityService: connectivityService));
  Get.put(GetDeviceGetx(getDeviceUsecase: usecaseConfig.getDeviceUsecase!));

  Get.put(TravelByIdAlertGetx(
      travelByIdUsecase: usecaseConfig.travelByIdUsecase!,
      connectivityService: connectivityService));

  Get.put(DestinoController(
    getSearchHistoryUsecase: usecaseConfig.getSearchHistoryUsecase!,
    saveSearchHistoryUsecase: usecaseConfig.saveSearchHistoryUsecase!,
    getPlaceDetailsAndMoveUsecase: usecaseConfig.getPlaceDetailsAndMoveUsecase!,
    getPlacePredictionsUsecase: usecaseConfig.getPlacePredictionsUsecase!,
  ));
  Get.put(MapDataController(getSearchHistoryUsecase: usecaseConfig.getSearchHistoryUsecase!, saveSearchHistoryUsecase: usecaseConfig.saveSearchHistoryUsecase!, getPlaceDetailsAndMoveUsecase: usecaseConfig.getPlaceDetailsAndMoveUsecase!, getPlacePredictionsUsecase: usecaseConfig.getPlacePredictionsUsecase!, calculateDistanceUsecase: usecaseConfig.calculateDistanceUsecase, getRouteUsecase: usecaseConfig.getRouteUsecase, getEncodedPointsUsecase: usecaseConfig.getEncodedPointsUsecase, decodePolylineUsecase: usecaseConfig.decodePolylineUsecase, getDurationUsecase: usecaseConfig.getDurationUsecase));
  Get.put(
      LogingoogleGetx(loginGoogleUsecase: usecaseConfig.loginGoogleUsecase!));

  Get.put(RejecttravelofferGetx(
      rejectTravelOfferUsecase: usecaseConfig.rejectTravelOfferUsecase!));
  Get.put(TravelwithtariffGetx(
      confirmTravelWithTariffUsecase:
          usecaseConfig.confirmTravelWithTariffUsecase!));
  Get.put(GetGendersGetx(getGendersUsecase: usecaseConfig.getGendersUsecase!));
  //Get.put( MapController(getSearchHistoryUsecase: usecaseConfig.getSearchHistoryUsecase!,saveSearchHistoryUsecase: usecaseConfig.saveSearchHistoryUsecase!,getPlaceDetailsAndMoveUsecase: usecaseConfig.getPlaceDetailsAndMoveUsecase!, getPlacePredictionsUsecase: usecaseConfig.getPlacePredictionsUsecase!, ),);
  Get.put(ModalController());
  Get.put(NotificationController());

  Get.put(RemovedataaccountGetx(
      removeDataAccountUsecase: usecaseConfig.removeDataAccountUsecase!));

  Get.put(OffernegotiationGetx(
      offerNegotiationUsecase: usecaseConfig.offerNegotiationUsecase!));
  Get.put(CreateRecoveryCodeController(
      createRecoveryCodeUsecase: usecaseConfig.createRecoveryCodeUsecase!,
      checkRecoveryCodeUsecase: usecaseConfig.checkRecoveryCodeUsecase!,
      updatePasswordUsecase: usecaseConfig.updatePasswordUsecase!));

  Get.put(NotificationService(navigatorKey));
  await Get.find<NotificationService>().initialize();
        }),
        theme: AppThemeCustom().getTheme(mode: ThemeMode.light, context: context),
        unknownRoute: AppPages.unknownRoute,
        getPages: AppPages.routes,
        initialRoute: RoutesNames.welcomePage,
    )
    );
  }
}
