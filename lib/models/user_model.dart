// models/user_model.dart

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String? parseString(dynamic value) {
      if (value == null) return null;
      return value.toString().trim();
    }

    return UserModel(
      id: parseInt(json['id']),
      name: parseString(json['name']) ?? '',
      email: parseString(json['email']) ?? '',
      phone: parseString(json['phone']),
      address: parseString(json['address']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
    };
  }

  // ✅ CopyWith method for easy updates
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  // ✅ Helper to check if phone is available
  bool get hasPhone => phone != null && phone!.isNotEmpty;

  // ✅ Helper to get formatted phone
  String get formattedPhone {
    if (!hasPhone) return 'Not available';
    return phone!;
  }

  // ✅ Helper to get display name
  String get displayName {
    return name.isEmpty ? 'Caregiver' : name;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, phone: $phone, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}