
class NotificationModel {
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;

  NotificationModel({this.title, this.body, this.data});

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['title'],
      body: json['body'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'data': data,
    };
  }
}
