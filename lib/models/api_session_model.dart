class ApiSessionModel {
  final String id;
  final String name; // Custom session name, defaults to id initially
  final DateTime startTime;

  ApiSessionModel({
    required this.id,
    required this.name,
    required this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
    };
  }

  factory ApiSessionModel.fromMap(Map<String, dynamic> map) {
    return ApiSessionModel(
      id: map['id'],
      name: map['name'] ??
          map['id'], // Fallback needed for existing records before migration
      startTime: DateTime.parse(map['startTime']),
    );
  }
}
