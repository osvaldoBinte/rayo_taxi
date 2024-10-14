import 'package:flutter/material.dart';
import 'package:rayo_taxi/features/mapa/presentation/page/travel_id_page.dart';
import 'package:rayo_taxi/features/travel/data/models/travel_alert_model.dart'; 

class AnimatedModalBottomSheet extends StatefulWidget {
  final int idTravel; 
  AnimatedModalBottomSheet({required this.idTravel});

  @override
  _AnimatedModalBottomSheetState createState() => _AnimatedModalBottomSheetState();
}

class _AnimatedModalBottomSheetState extends State<AnimatedModalBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_animation),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Container(
              color: Colors.white,
              child: TravelIdPage(idTravel: widget.idTravel),  // Pasa travelList a TravelRoute
            ),
          ),
        ),
      ),
    );
  }
}
