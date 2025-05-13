import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/features/travel/presentation/getx/notification/notificationcontroller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelAlert/travel_alert_getx.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/TravelsAlert/travels_alert_getx.dart';

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
  
  // Variables para controlar la actualización con retraso
  Timer? _updateTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Verificar notificaciones al inicio con un ligero retraso
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdateNeeded(initialDelay: true);
    });
    
    // Si el NotificationController expone una variable reactiva para notificaciones pendientes, usarla
    if (notificationController.tripAccepted != null) {
      ever(notificationController.tripAccepted, (accepted) {
        if (accepted == true) {
          print('DEBUG: Viaje aceptado detectado, programando actualización');
          _scheduleUpdate();
        }
      });
    }
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
    
    // Usar retraso más largo para el inicio, más corto para actualizaciones posteriores
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
      final hasNotification = await _checkForPendingNotification();
      
      if (hasNotification) {
        print('DEBUG: Notificación pendiente encontrada, actualizando datos');
        await _updateTravelData();
      } else {
        print('DEBUG: No se encontraron notificaciones pendientes');
      }
    } catch (e) {
      print('ERROR durante verificación de actualización: $e');
    }
  }
  
  // Actualizar datos de viaje
  Future<void> _updateTravelData() async {
    if (_isUpdating) {
      return;
    }
    
    // Prevenir actualizaciones muy cercanas (menos de 2 segundos)
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateTimestamp < 2000) {
      print('DEBUG: Omitiendo actualización (demasiado cercana a la anterior)');
      return;
    }
    
    _isUpdating = true;
    _lastUpdateTimestamp = now;
    
    try {
      print('DEBUG: Iniciando actualización de datos de viaje');
      
      // Usar waitForOperationsToComplete para asegurar que se completen ambas operaciones
      await _waitForOperationsToComplete(
        currentTravelGetx: currentTravelGetx,
        travelAlertGetx: travelAlertGetx
      );
      
      print('DEBUG: Actualización completada correctamente');
      
      // Limpiar notificación después de actualizar
      await _clearLastNotification();
    } catch (e) {
      print('ERROR en actualización de datos: $e');
    } finally {
      _isUpdating = false;
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
  
  Future<void> _waitForOperationsToComplete({
      required CurrentTravelGetx currentTravelGetx,
      required TravelsAlertGetx travelAlertGetx}) async {
    final currentTravelCompleter = Completer();
    final travelsAlertCompleter = Completer();
    
    // Configurar listeners para detectar cuando las operaciones se completan
    final currentTravelSubscription = ever(currentTravelGetx.state, (state) {
      if ((state is TravelAlertLoaded || state is TravelAlertFailure) && 
          !currentTravelCompleter.isCompleted) {
        print('DEBUG: Completada actualización de CurrentTravel');
        currentTravelCompleter.complete();
      }
    });
    
    final travelsAlertSubscription = ever(travelAlertGetx.state, (state) {
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
      // Cancelar el timeout y las suscripciones
      timeoutTimer.cancel();
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
      final hasStoredNotification = storedMessage != null;
      
      // Verificar también NotificationController si está disponible
      final hasControllerNotification = 
          notificationController.tripAccepted.value == true || 
          (notificationController.lastNotification.value != null);
      
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
    return widget.child;
  }
}