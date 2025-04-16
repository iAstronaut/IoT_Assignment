class Patient {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String? address;
  final String? phone;
  final String? medicalHistory;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.address,
    this.phone,
    this.medicalHistory,
    required this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as int,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      medicalHistory: json['medicalHistory'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'address': address,
      'phone': phone,
      'medicalHistory': medicalHistory,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    String? address,
    String? phone,
    String? medicalHistory,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}