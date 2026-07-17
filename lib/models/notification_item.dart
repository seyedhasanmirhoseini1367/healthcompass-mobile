class NotificationItem {
  final String id;
  final String type;
  final String typeDisplay;
  final String title;
  final String message;
  final bool isRead;
  final String? link;
  final String? createdAt;

  const NotificationItem({
    required this.id,
    this.type = '',
    this.typeDisplay = '',
    required this.title,
    this.message = '',
    this.isRead = false,
    this.link,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: (json['id'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        typeDisplay: (json['type_display'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        isRead: json['is_read'] == true,
        link: json['link']?.toString(),
        createdAt: json['created_at']?.toString(),
      );

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        type: type,
        typeDisplay: typeDisplay,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        link: link,
        createdAt: createdAt,
      );
}
