class GoogleMensajeModel {
  final bool ok;
  final String message;

  GoogleMensajeModel({
    required this.ok,
    required this.message,
  });

  factory GoogleMensajeModel.fromJson(Map<String, dynamic> json) {
    return GoogleMensajeModel(
      ok: json['ok'] ?? false,
      message: json['message'] ?? '',
    );
  }
}