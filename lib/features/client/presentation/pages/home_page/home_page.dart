import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/theme/App_Theme.dart';
import 'package:rayo_taxi/features/client/presentation/pages/home_page/HomeController.dart';
import 'package:rayo_taxi/features/client/presentation/pages/perfil/get_client_page.dart';
import 'package:rayo_taxi/features/travel/presentation/page/select_map/select_map.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/presentation/page/travelID/travels_page.dart';

class HomePage extends StatefulWidget {
  final int selectedIndex;
  
  HomePage({required this.selectedIndex});
  
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  // Inicializar el controlador y asegurarse de que se mantenga en memoria
  final HomeController controller = Get.put(HomeController(), permanent: true);
  
  // Inicializar páginas
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    // Inicializar páginas
    _pages = [
      TravelsPage(),
      SelectMap(),
      GetClientPage(),
    ];
    
    // Establecer el índice después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Configurando índice inicial a: ${widget.selectedIndex}');
      controller.selectedIndex.value = widget.selectedIndex;
      
      // Solicitar permisos
      _requestPermissions();
    });
  }
  
  Future<void> _requestPermissions() async {
    try {
      await controller.requestLocationPermission();
      await controller.requestNotificationPermission();
      await controller.requestPhonePermission();
    } catch (e) {
      print('Error al solicitar permisos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => controller.handleBackButton(widget.selectedIndex),
      child: Scaffold(
         backgroundColor:Theme.of(context).primaryColor,
       appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
        extendBody: true,
        body: SafeArea(
          child: Stack(
            children: [
              // Usar GetX para el IndexedStack
              GetX<HomeController>(
                builder: (ctrl) {
                  print('Construyendo IndexedStack con índice: ${ctrl.selectedIndex.value}');
                  return IndexedStack(
                    index: ctrl.selectedIndex.value,
                    children: _pages,
                  );
                }
              ),
              
              // Mostrar la barra de navegación solo si el teclado no está visible
              Align(
                alignment: Alignment.bottomCenter,
                child: Builder(
                  builder: (context) {
                    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
                    
                    if (isKeyboardVisible) {
                      return SizedBox.shrink();
                    }
                    
                    // Usar GetX para la barra de navegación
                    return GetX<HomeController>(
                      builder: (ctrl) {
                        return CurvedNavigationBar(
                          index: ctrl.selectedIndex.value,
                          backgroundColor: Colors.transparent,
                          color: Theme.of(context).primaryColor,
                          buttonBackgroundColor:
                              Theme.of(context).colorScheme.CurvedIconback,
                          height: 75,
                          items: <Widget>[
                            _buildIcon('assets/images/taxi/icons-viaje.png', 0, ctrl.selectedIndex.value),
                            _buildIcon("assets/images/taxi/icon-taxi.png", 1, ctrl.selectedIndex.value),
                            _buildIcon(Icons.person, 2, ctrl.selectedIndex.value),
                          ],
                          animationDuration: const Duration(milliseconds: 700),
                          animationCurve: Curves.easeInOut,
                          onTap: (index) {
                            print('Tapped index: $index');
                            ctrl.setIndex(index);
                          },
                        );
                      }
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para construir los iconos sin usar Obx
  Widget _buildIcon(dynamic icon, int index, int currentIndex) {
    bool isSelected = currentIndex == index;
    return Container(
      margin: EdgeInsets.only(bottom: isSelected ? 4 : 0),
      height: isSelected ? 40 : 60,
      child: icon is IconData
          ? Icon(
              icon,
              size: isSelected ? 30 : 40,
              color: isSelected
                  ? Theme.of(context).colorScheme.CurvedNavigationIcono
                  : Theme.of(context).colorScheme.CurvedNavigationIcono2,
            )
          : Image.asset(
              icon,
              width: isSelected ? 30 : 40,
              height: isSelected ? 30 : 40,
              color: isSelected
                  ? Theme.of(context).colorScheme.CurvedNavigationIcono
                  : Theme.of(context).colorScheme.CurvedNavigationIcono2,
            ),
    );
  }
}