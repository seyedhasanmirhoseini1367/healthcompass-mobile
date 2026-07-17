class Appointment {
  final String id;
  final String title;
  final String doctorName;
  final String location;
  final String appointmentDatetime;
  final String notes;
  final bool remind24h;
  final bool remind3h;
  final bool remind2h;
  final bool remind1h;
  final bool isCompleted;
  final bool isCancelled;
  final String? createdAt;

  const Appointment({
    required this.id,
    required this.title,
    this.doctorName = '',
    this.location = '',
    required this.appointmentDatetime,
    this.notes = '',
    this.remind24h = false,
    this.remind3h = false,
    this.remind2h = false,
    this.remind1h = false,
    this.isCompleted = false,
    this.isCancelled = false,
    this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        doctorName: (json['doctor_name'] ?? '').toString(),
        location: (json['location'] ?? '').toString(),
        appointmentDatetime: (json['appointment_datetime'] ?? '').toString(),
        notes: (json['notes'] ?? '').toString(),
        remind24h: json['remind_24h'] == true,
        remind3h: json['remind_3h'] == true,
        remind2h: json['remind_2h'] == true,
        remind1h: json['remind_1h'] == true,
        isCompleted: json['is_completed'] == true,
        isCancelled: json['is_cancelled'] == true,
        createdAt: json['created_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'doctor_name': doctorName,
        'location': location,
        'appointment_datetime': appointmentDatetime,
        'notes': notes,
        'remind_24h': remind24h,
        'remind_3h': remind3h,
        'remind_2h': remind2h,
        'remind_1h': remind1h,
      };
}
