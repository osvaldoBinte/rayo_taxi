import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rayo_taxi/common/theme/app_color.dart';
import 'package:rayo_taxi/features/travel/data/models/travel/travel_alert_model.dart';
import 'package:rayo_taxi/features/travel/presentation/page/ratetrip/rate_trip_controller.dart';

class RateTrip extends StatelessWidget {
  final TravelAlertModel travel;
  final RateTripController controller;

  const RateTrip({
    Key? key,
    required this.travel,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ContentBox(
        travel: travel,
        controller: controller,
      ),
    );
  }
}

class ContentBox extends StatefulWidget {
  final TravelAlertModel travel;
  final RateTripController controller;

  const ContentBox({
    Key? key,
    required this.travel,
    required this.controller,
  }) : super(key: key);

  @override
  State<ContentBox> createState() => _ContentBoxState();
}

class _ContentBoxState extends State<ContentBox> {
  int rating = 0;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Stack(
      children: [
        Container(
          padding: const EdgeInsets.only(
            left: 20,
            top: 65,
            right: 20,
            bottom: 20,
          ),
          margin: const EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Cómo fue tu experiencia?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Califica tu experiencia con el Conductor ${widget.travel.driver}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
                Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < widget.controller.rating.value ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
              onPressed: widget.controller.isLoading
                  ? null
                  : () => widget.controller.updateRating(index + 1),
            );
          }),
        ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: widget.controller.isLoading
                          ? null
                          : () async {
                              await widget.controller.skipRating(widget.travel);
                            },
                      child: const Text(
                        'Omitir',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:  Theme.of(context).colorScheme.button,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    onPressed: (widget.controller.rating.value > 0 && !widget.controller.isLoading)
            ? () async {
                await widget.controller.submitRating(
                  widget.travel,
                  widget.controller.rating.value,
                );
              }
            : null,
                      child: widget.controller.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Calificar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          child: CircleAvatar(
            backgroundColor: Colors.grey[900]!,
            radius: 45,
            child: _buildAvatarContent(),
          ),
        ),
      ],
    ));
  }

  Widget _buildAvatarContent() {
    try {
      return ClipOval(
        child: Image.asset(
          widget.travel.path_photo,
          height: 90,
          width: 90,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              widget.travel.driver[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Text(
        widget.travel.driver[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 40,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }
}

Future<int?> showRateTripAlert(BuildContext context, TravelAlertModel travel) {
  if (travel.pending_qualification == 2) {
    final RateTripController controller = Get.find<RateTripController>();
    controller.resetState();
    
    return showDialog<int>(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) => WillPopScope(
        onWillPop: () async => false, 
        child: RateTrip(
          travel: travel,
          controller: controller,
        ),
      ),
    );
  }
  return Future.value(null);
}