// ayuda_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/client/domain/entities/client.dart';
import '../../../../travel/presentation/page/current_travel/emergency_button.dart';
import 'ayuda_controller.dart';
// ayuda_page.dart
class AyudaPage extends GetView<AyudaController> {
  final Client client;

  const AyudaPage({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(AyudaController(client: client));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.button,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                onPressed: controller.hacerLlamada,
                icon: const Icon(
                  Icons.phone,
                  size: 24,
                ),
                label: const Text(
                  'Contactar por Teléfono',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.whatsApp,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                onPressed: controller.abrirWhatsApp,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/whatsApp.png',
                      height: 24,
                      width: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Contactar por WhatsApp',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}