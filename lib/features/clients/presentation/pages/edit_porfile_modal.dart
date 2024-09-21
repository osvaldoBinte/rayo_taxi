
import 'package:flutter/material.dart';
import 'package:rayo_taxi/features/clients/presentation/pages/put_client_page.dart';

import '../../domain/entities/client.dart';

class EditProfileModal extends StatefulWidget {
  final Client client;

  const EditProfileModal({required this.client});

  @override
  _EditProfileModalState createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: EditProfilePage(client: widget.client),
      ),
    );
  }
}
