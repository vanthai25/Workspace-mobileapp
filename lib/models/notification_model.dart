class AppNotification {
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;
  final String? notificationType;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.notificationType,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      notificationType: json['notificationType'],
    );
  }
}