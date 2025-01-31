import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:rayo_taxi/common/app/splash_screen.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/common/routes/router.dart';
import 'package:rayo_taxi/common/settings/app_lifecycle_handler.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/common/theme/App_Theme.dart';
import 'package:rayo_taxi/main.dart';

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
     initialBinding: BindingsBuilder(() {
          Get.put(NavigationService());
        }),
        theme: AppThemeCustom().getTheme(mode: ThemeMode.light, context: context),
        unknownRoute: AppPages.unknownRoute,
        getPages: AppPages.routes,
        initialRoute: RoutesNames.welcomePage,
    )
    );
  }
}
