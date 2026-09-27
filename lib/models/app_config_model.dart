class AppConfig {
  final bool isMaintenanceMode;
  final String? maintenanceMessage;
  final String androidVersion;
  final String iosVersion;
  final bool forceUpdate;
  final String? updateMessage;
  final String? androidDownloadUrl;
  final String? iosDownloadUrl;

  AppConfig({
    required this.isMaintenanceMode,
    this.maintenanceMessage,
    required this.androidVersion,
    required this.iosVersion,
    required this.forceUpdate,
    this.updateMessage,
    this.androidDownloadUrl,
    this.iosDownloadUrl,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      isMaintenanceMode: json['isMaintenanceMode'] ?? false,
      maintenanceMessage: json['maintenanceMessage'],
      androidVersion: json['androidVersion'] ?? '1.0.0',
      iosVersion: json['iosVersion'] ?? '1.0.0',
      forceUpdate: json['forceUpdate'] ?? false,
      updateMessage: json['updateMessage'],
      androidDownloadUrl: json['androidDownloadUrl'],
      iosDownloadUrl: json['iosDownloadUrl'],
    );
  }
}