import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rayo_taxi/features/client/presentation/pages/login/loginclient_getx.dart';
import 'package:rayo_taxi/features/client/presentation/pages/Widget/loaderScreen%20/custom_loading_screen.dart';
import 'package:rayo_taxi/features/client/presentation/pages/ayudaPage/ayuda_page.dart';
import 'package:rayo_taxi/features/client/presentation/pages/put_client/edit_porfile_modal.dart';
import 'package:rayo_taxi/features/client/presentation/pages/login/login_clients_page.dart';
import 'package:rayo_taxi/features/client/presentation/pages/pagos/animated_modal_bottom.dart';
import 'package:rayo_taxi/features/client/presentation/pages/perfil/privacy_notices.dart';
import 'package:rayo_taxi/features/travel/presentation/Travelgetx/removeDataAccount/removeDataAccount_getx.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../getxs/get/get_client_getx.dart';
import '../../getxs/calculateAge/calculateAge_getx.dart';
import 'package:quickalert/quickalert.dart';
import 'package:rayo_taxi/features/client/presentation/pages/Widget/card_button.dart';
import 'package:rayo_taxi/features/client/presentation/pages/Widget/list_option.dart';

class GetClientPage extends StatefulWidget {
  const GetClientPage({super.key});

  @override
  State<GetClientPage> createState() => _GetClientPageState();
}

class _GetClientPageState extends State<GetClientPage> {
  late StreamSubscription<ConnectivityResult> subscription;
  final GetClientGetx getClientGetx = Get.find<GetClientGetx>();
  final CalculateAgeGetx calculateAgeGetx = Get.find<CalculateAgeGetx>();
  final LoginclientGetx _loginGetx = Get.find<LoginclientGetx>();
  final RemovedataaccountGetx _removedataaccountGetx =
      Get.find<RemovedataaccountGetx>();

  final _picker = ImagePicker();
  String? _imagePath;
 
  Future<void> _logout() async {
   _loginGetx.logoutAlert();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getClientGetx.fetchCoDetails(FetchgetDetailsEvent());
      final state = getClientGetx.state.value;
      if (state is GetClientLoaded) {
        final client = state.client.isNotEmpty ? state.client[0] : null;
        if (client != null && client.birthdate != null) {
          calculateAgeGetx.calculateAge(client.birthdate!);
        }
      }
    });
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se perdió la conectividad Wi-Fi'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        getClientGetx.fetchCoDetails(FetchgetDetailsEvent());
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final state = getClientGetx.state.value;

          if (state is GetClientLoading) {
            return const CustomLoadingScreen();
          } else if (state is GetClientFailure) {
            return Center(
              child: Text(
                state.error,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 18),
              ),
            );
          } else if (state is GetClientLoaded) {
            final client = state.client.isNotEmpty ? state.client[0] : null;

            if (client == null) {
              return const Center(
                child: Text(
                  'Cliente no encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _imagePath != null
                              ? FileImage(File(_imagePath!))
                              : null,
                          child: _imagePath == null
                              ? ClipOval(
                                  child: Image.network(
                                    client.path_photo ?? '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return Text(
                                        (client.name ?? '?')[0].toUpperCase(),
                                        style:  TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.avatar,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                         
                          Text(
                            '${client.email ?? 'Sin email'}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.icongreen,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CardButton(
                      icon: Icons.logout,
                      label: 'Cerrar Sesión',
                      onPressed: _logout,
                    ),
                    CardButton(
                      icon: Icons.edit,
                      label: 'Editar',
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (BuildContext context) {
                            return FractionallySizedBox(
                              heightFactor: 0.8,
                              child: Column(
                                children: <Widget>[
                                  SizedBox(
                                    height: 10,
                                    width: 70,
                                    child: DecoratedBox(
                                        decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                    )),
                                  ),
                                  Expanded(
                                    child: EditProfileModal(client: client),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ListOption(
                    icon: Icons.help_outline,
                    title: 'Ayuda',
                    subtitle:
                        '¿Te gustaría que te ayude con algo más relacionado con tu aplicación?',
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (BuildContext context) {
                          return FractionallySizedBox(
                            heightFactor: 0.8,
                            child: Column(
                              children: <Widget>[
                                SizedBox(
                                  height: 10,
                                  width: 70,
                                  child: DecoratedBox(
                                      decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8)),
                                  )),
                                ),
                                Expanded(
                                  child: AyudaPage(client: client),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                ListOption(
                  icon: Icons.privacy_tip,
                  title: 'Aviso de Privacidad',
                  subtitle: 'Detalles de nuestras políticas y condiciones',
                  onPressed: () => _showPdfModal(context),
                ),
                ListOption(
                  icon: Icons.delete_forever,
                  title: 'Eliminar cuenta',
                  subtitle: 'Elimina tu cuenta de forma permanente',
                  cardColor: Colors.red.shade100,
                  onPressed: () {
                    _removedataaccountGetx.confirmDeleteAccount();
                  },
                ),
                const SizedBox(height: 80),
              ],
            );
          }
          return Container();
        }),
      ),
    );
  }

  void _showPdfModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 10,
                width: 70,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                )),
              ),
              Expanded(
                child: PrivacyPolicyView(),
              ),
            ],
          ),
        );
      },
    );
  }
}
