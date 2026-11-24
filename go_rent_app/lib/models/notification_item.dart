// Data notifikasi dari GET /notifications
class NotificationItem {
  final int id;
  final int userId;
  final int? bookingId; // null untuk notifikasi promo/reminder umum
  final String title;
  final String description;
  final String type; // order, promo, reminder
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.title,
    required this.description,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      bookingId: json['booking_id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      // created_at berbentuk "YYYY-MM-DD HH:MM:SS" (waktu lokal server)
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'booking_id': bookingId,
    'title': title,
    'description': description,
    'type': type,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

  // Salinan dengan status baca baru (dipakai saat tandai dibaca)
  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      userId: userId,
      bookingId: bookingId,
      title: title,
      description: description,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
