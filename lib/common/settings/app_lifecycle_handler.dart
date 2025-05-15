import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/common/routes/%20navigation_service.dart';
import 'package:rayo_taxi/common/settings/routes_names.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelsAlert/travels_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rayo_taxi/features/travel/presentation/page/widgets/customSnacknar.dart';

class AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const AppLifecycleHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler> with WidgetsBindingObserver {
  final CurrentTravelGetx currentTravelGetx = Get.find<CurrentTravelGetx>();
  final TravelsAlertGetx travelAlertGetx = Get.find<TravelsAlertGetx>();
  final NotificationController notificationController = Get.find<NotificationController>();
  
  static const String _lastNotificationKey = 'lastNotification';
  bool _isUpdating = false;
  int _lastUpdateTimestamp = 0;
  Timer? _updateTimer;
  
  // Observador del árbol de navegación para capturar cambios de ruta
  RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Configurar verificación de notificaciones periódica
    _setupPeriodicNotificationCheck();
    
    // Verificar notificaciones al inicio con un ligero retraso
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdateNeeded(initialDelay: true);
    });
    
    // Observar tripAccepted
    if (notificationController.tripAccepted != null) {
      ever(notificationController.tripAccepted, (accepted) {
        if (accepted == true) {
          print('DEBUG: Viaje aceptado detectado, programando actualización');
          _scheduleUpdate();
        }
      });
    }
    
    // Observar lastNotification
    ever(notificationController.lastNotification, (notification) {
      if (notification != null) {
        print('DEBUG: Nueva notificación detectada, programando actualización');
        _scheduleUpdate();
      }
    });
    
    // Suscribirse a los cambios de ruta con GetX
    ever(Get.routing.obs, (_) {
      print('DEBUG: Cambio de ruta detectado, verificando notificaciones pendientes');
      _scheduleUpdate();
    });
  }

  // Configurar verificación periódica para asegurar que las notificaciones siempre se procesen
  void _setupPeriodicNotificationCheck() {
    // Verificar cada 20 segundos si hay notificaciones pendientes
    Timer.periodic(Duration(seconds: 20), (timer) {
      if (!_isUpdating) {
        _checkForPendingNotification().then((hasPendingNotification) {
          if (hasPendingNotification) {
            print('DEBUG: Notificación pendiente encontrada en verificación periódica');
            _scheduleUpdate();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Programar actualización con retraso
  void _scheduleUpdate() {
    _updateTimer?.cancel();
    
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateTimestamp < 2000) {
      print('DEBUG: Omitiendo actualización duplicada (demasiado cercana a la anterior)');
      return;
    }
    
    // Usar un retraso corto para actualizaciones
    _updateTimer = Timer(Duration(milliseconds: 500), () {
      _checkForUpdateNeeded();
    });
  }
  
  // Verificar si es necesario actualizar los datos
  Future<void> _checkForUpdateNeeded({bool initialDelay = false}) async {
    if (_isUpdating) {
      print('DEBUG: Ya actualizando, ignorando solicitud');
      return;
    }
    
    // Si es la verificación inicial, esperar un poco más
    if (initialDelay) {
      await Future.delayed(Duration(milliseconds: 1000));
    }
    
    try {
      final notificationInfo = await _getNotificationInfo();
      final title = notificationInfo['title'];
      
      if (title != null) {
        print('DEBUG: Notificación pendiente encontrada: $title');
        await _processNotification(title, notificationInfo['body']);
      } else {
        print('DEBUG: No se encontraron notificaciones pendientes');
      }
    } catch (e) {
      print('ERROR durante verificación de actualización: $e');
    }
  }
  
  // Procesar la notificación según su tipo
  Future<void> _processNotification(String title, String? body) async {
    if (_isUpdating) {
      return;
    }
    
    _isUpdating = true;
    _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
    
    try {
      print('DEBUG: Procesando notificación: $title');
      
      // Para todos los tipos de notificaciones, primero cargar los datos
      await _waitForOperationsToComplete(
        currentTravelGetx: currentTravelGetx,
        travelAlertGetx: travelAlertGetx
      );
      
      // Procesar según el tipo de notificación
      if (title == 'Nuevo precio para tu viaje') {
        // En este caso, navegar al home usando la ruta nombrada
        _navigateToHome(1);
      } 
      else if (title == 'Tu viaje fue aceptado' || title == "Contraoferta aceptada por el conductor") {
        // Mostrar alerta de aceptación
        _navigateToHome(1, showAlert: true, alertConfig: {
          'title': title,
          'body': body ?? '',
          'type': 'accept'
        });
      } 
      else if (title == 'Viaje terminado') {
        // Navegar a home y mostrar alerta
        _navigateToHome(1, showAlert: false, alertConfig: {
          'title': title,
          'body': body ?? '',
          'type': 'info'
        });
      } 
      else {
        // Para otros tipos de notificaciones
        if (Get.context != null && body != null) {
          _showQuickAlert(title, body);
        }
      }
      
      print('DEBUG: Notificación procesada correctamente');
      await _clearLastNotification();
    } catch (e) {
      print('ERROR en procesamiento de notificación: $e');
      CustomSnackBar.showError('', 'Error al procesar la notificación: $e');
    } finally {
      _isUpdating = false;
    }
  }
  
  // Método mejorado para navegar al home que funciona independientemente del estado de navegación
  void _navigateToHome(int selectedIndex, {bool showAlert = false, Map<String, dynamic>? alertConfig}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usar offAllNamed para asegurar que volvemos a la ruta base
      Get.offAllNamed(
        RoutesNames.homePage,
        arguments: {'selectedIndex': selectedIndex},
      );
      
      // Si se debe mostrar una alerta, hacerlo después de navegar
      if (showAlert && alertConfig != null) {
        // Esperar a que la navegación termine antes de mostrar la alerta
        Future.delayed(Duration(milliseconds: 300), () {
          final title = alertConfig['title'] as String;
          final body = alertConfig['body'] as String;
          final type = alertConfig['type'] as String;
          
          if (type == 'accept') {
            _showAcceptAlert(title, body);
          } else if (type == 'info') {
            _showQuickAlert(title, body);
          }
        });
      }
    });
  }
  
  // Alerta para viajes aceptados
  void _showAcceptAlert(String title, String body) {
    try {
      if (Get.context != null) {
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: title,
          text: body,
          confirmBtnText: 'OK',
          onConfirmBtnTap: () {
            // Cerrar la alerta
            Navigator.of(Get.context!).pop();
          },
        );
      } else {
        print('DEBUG: Get.context es null, no se puede mostrar alerta');
      }
    } catch (e) {
      print('ERROR al mostrar alerta de aceptación: $e');
    }
  }
  
  // Alerta general para otros tipos de notificaciones
  void _showQuickAlert(String title, String body) {
    try {
      if (Get.context != null) {
        Future.microtask(() {
          QuickAlert.show(
            context: Get.context!,
            type: QuickAlertType.info,
            title: title,
            text: body,
            confirmBtnText: 'OK',
            onConfirmBtnTap: () {
              if (title == 'Viaje terminado') {
                Get.find<NotificationController>().tripAccepted.value = false;
                Get.find<ModalController>().imageUrl.value = 'assets/images/viajes/add_travel.gif';
                Get.find<ModalController>().modalText.value = 'Buscando chofer...';
              }

              currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
              Navigator.of(Get.context!).pop();
            },
          );
        });
      } else {
        print('DEBUG: Get.context es null, no se puede mostrar alerta');
        // Guardar la notificación para mostrarla cuando haya contexto
        _saveNotificationForLater(title, body);
      }
    } catch (e) {
      print('ERROR al mostrar alerta rápida: $e');
    }
  }

  // Guardar notificación para mostrarla más tarde cuando haya contexto disponible
  void _saveNotificationForLater(String title, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_alert_title', title);
      await prefs.setString('pending_alert_body', body);
      print('DEBUG: Notificación guardada para mostrar más tarde');
    } catch (e) {
      print('ERROR al guardar notificación para más tarde: $e');
    }
  }

  Future<void> _waitForOperationsToComplete({
    required CurrentTravelGetx currentTravelGetx,
    required TravelsAlertGetx travelAlertGetx
  }) async {
    final currentTravelCompleter = Completer();
    final travelsAlertCompleter = Completer();
    
    // Configurar listeners para detectar cuando las operaciones se completan
    final currentTravelDisposer = ever(currentTravelGetx.state, (state) {
      if ((state is TravelAlertLoaded || state is TravelAlertFailure) && 
          !currentTravelCompleter.isCompleted) {
        print('DEBUG: Completada actualización de CurrentTravel');
        currentTravelCompleter.complete();
      }
    });
    
    final travelsAlertDisposer = ever(travelAlertGetx.state, (state) {
      if ((state is TravelsAlertLoaded || state is TravelsAlertFailure) && 
          !travelsAlertCompleter.isCompleted) {
        print('DEBUG: Completada actualización de TravelsAlert');
        travelsAlertCompleter.complete();
      }
    });
    
    // Configurar timeout para evitar bloqueos
    final timeoutTimer = Timer(Duration(seconds: 10), () {
      if (!currentTravelCompleter.isCompleted) {
        print('ADVERTENCIA: Timeout en CurrentTravel, forzando completion');
        currentTravelCompleter.complete();
      }
      if (!travelsAlertCompleter.isCompleted) {
        print('ADVERTENCIA: Timeout en TravelsAlert, forzando completion');
        travelsAlertCompleter.complete();
      }
    });

    // Iniciar operaciones
    try {
      print('DEBUG: Iniciando fetchCoDetails para TravelsAlert');
      travelAlertGetx.fetchCoDetails(FetchtravelsDetailsEvent());
      
      print('DEBUG: Iniciando fetchCoDetails para CurrentTravel');
      currentTravelGetx.fetchCoDetails(FetchgetDetailsssEvent());
      
      // Esperar a que se completen ambas operaciones
      await Future.wait([
        currentTravelCompleter.future,
        travelsAlertCompleter.future
      ]);
      
      print('DEBUG: Ambas operaciones completadas exitosamente');
    } catch (e) {
      print('ERROR en waitForOperationsToComplete: $e');
    } finally {
      // Cancelar el timeout y limpiar los listeners
      timeoutTimer.cancel();
      currentTravelDisposer();
      travelsAlertDisposer();
    }
  }

  // Obtener información completa de la notificación
  Future<Map<String, String?>> _getNotificationInfo() async {
    Map<String, String?> result = {
      'title': null,
      'body': null,
    };
    
    try {
      // Primero verificar en el controlador de notificaciones
      if (notificationController.lastNotification.value != null) {
        final notification = notificationController.lastNotification.value!;
        result['title'] = notification.notification?.title;
        result['body'] = notification.notification?.body;
        
        // Si tenemos título y cuerpo, devolver directamente
        if (result['title'] != null && result['body'] != null) {
          return result;
        }
      }
      
      // Si no está disponible en el controlador, intentar obtenerlo de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Asegurar datos frescos
      final notificationString = prefs.getString(_lastNotificationKey);
      
      if (notificationString != null && notificationString.isNotEmpty) {
        try {
          final notificationData = Map<String, dynamic>.from(
            (notificationString.startsWith('{')) 
              ? Map<String, dynamic>.from(await json.decode(notificationString))
              : {}
          );
          
          // Intenta obtener el título y cuerpo de diferentes ubicaciones posibles
          result['title'] = notificationData['notification']?['title'] ?? 
                 notificationData['title'] ?? 
                 notificationData['data']?['title'];
                 
          result['body'] = notificationData['notification']?['body'] ?? 
                 notificationData['body'] ?? 
                 notificationData['data']?['body'];
        } catch (e) {
          print('ERROR al parsear notificación guardada: $e');
        }
      }
      
      // Verificar notificaciones pendientes guardadas
      final pendingTitle = prefs.getString('pending_alert_title');
      final pendingBody = prefs.getString('pending_alert_body');
      
      if (pendingTitle != null && result['title'] == null) {
        result['title'] = pendingTitle;
        result['body'] = pendingBody;
        // Limpiar notificaciones pendientes después de recuperarlas
        await prefs.remove('pending_alert_title');
        await prefs.remove('pending_alert_body');
      }
      
      return result;
    } catch (e) {
      print('ERROR al obtener información de notificación: $e');
      return result;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      print('DEBUG: App volvió a primer plano, verificando notificaciones...');
      
      // Esperar un poco para que la UI se estabilice
      _scheduleUpdate();
    } else if (state == AppLifecycleState.paused) {
      // App va a segundo plano
      print('DEBUG: App pasó a segundo plano');
    }
  }
  
  // Verificar si hay una notificación pendiente en SharedPreferences
  Future<bool> _checkForPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Asegurar datos frescos
      
      // Verificar todas las claves disponibles (para diagnóstico)
      final keys = prefs.getKeys();
      print('DEBUG: Claves en SharedPreferences: $keys');
      
      final storedMessage = prefs.getString(_lastNotificationKey);
      final pendingTitle = prefs.getString('pending_alert_title');
      final hasStoredNotification = storedMessage != null || pendingTitle != null;
      
      // Verificar también NotificationController si está disponible
      final hasControllerNotification = 
          notificationController.tripAccepted?.value == true || 
          notificationController.lastNotification.value != null;
      
      print('DEBUG: ¿Hay notificación guardada? $hasStoredNotification');
      print('DEBUG: ¿Hay notificación en controller? $hasControllerNotification');
      
      return hasStoredNotification || hasControllerNotification;
    } catch (e) {
      print('ERROR al verificar notificación pendiente: $e');
      return false;
    }
  }

  // Limpiar la notificación almacenada
  Future<void> _clearLastNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastNotificationKey);
      await prefs.remove('pending_alert_title');
      await prefs.remove('pending_alert_body');
      
      // Limpiar también el controlador
      if (Get.isRegistered<NotificationController>()) {
        await notificationController.clearNotification();
      }
      
      print('DEBUG: Notificación pendiente eliminada correctamente');
    } catch (e) {
      print('ERROR al eliminar notificación pendiente: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar notificaciones pendientes cada vez que se construye el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPendingNotification().then((hasPending) {
        if (hasPending) {
          _scheduleUpdate();
        }
      });
    });
    
    return widget.child;
  }
}

// Extensión del NavigationService actual
extension NavigationServiceExtension on NavigationService {
  // Modificar la función navigateToHome para manejar alertas
  Future<void> navigateToHomeWithAlert(int selectedIndex, {String? alertTitle, String? alertBody, String? alertType}) async {
    await navigateToHome(selectedIndex: selectedIndex);
    
    if (alertTitle != null && alertBody != null && Get.context != null) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (alertType == 'success') {
          QuickAlert.show(
            context: Get.context!,
            type: QuickAlertType.success,
            title: alertTitle,
            text: alertBody,
            confirmBtnText: 'OK',
          );
        } else {
          QuickAlert.show(
            context: Get.context!,
            type: QuickAlertType.info,
            title: alertTitle,
            text: alertBody,
            confirmBtnText: 'OK',
          );
        }
      });
    }
  }
}