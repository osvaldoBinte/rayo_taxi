import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LottieViewer(),
    );
  }
}

class LottieViewer extends StatelessWidget {
  final List<String> lottieUrls = [
    "https://lottie.host/4b6efc1d-1021-48a4-a3dd-df0eecbd8949/1CzFNvYv69.json",
    "https://lottie.host/4a367cbb-4834-44ba-997a-9a8a62408a99/keSVai2cNe.json",
    "https://lottie.host/6e431316-eca7-442c-8dc1-260ba57c2329/ds9skaDTtN.json",
    "https://lottie.host/bcf4608b-5b35-4c48-b2c9-c0126124a159/CFerLgDKdO.json",
    "https://lottie.host/570427d7-38f8-4de4-bacf-bb19b51afb5a/FyXEfSV0rb.json"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lottie Viewer"),
      ),
      body: PageView.builder(
        itemCount: lottieUrls.length,
        itemBuilder: (context, index) {
          return Center(
            child: Lottie.network(
              lottieUrls[index],
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
