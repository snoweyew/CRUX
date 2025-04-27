class UserModel {
  final String id;
  final String name;
  final String role;
  final String? email;
  final String selectedCity;
  final bool isEmailVerified;
  final String? visitorType;
  final String? state;
  final String? country;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.selectedCity = '',
    this.isEmailVerified = false,
    this.visitorType,
    this.state,
    this.country,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
      selectedCity: json['selectedCity'] as String? ?? '',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      visitorType: json['visitorType'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'email': email,
      'selectedCity': selectedCity,
      'isEmailVerified': isEmailVerified,
      'visitorType': visitorType,
      'state': state,
      'country': country,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? role,
    String? selectedCity,
    String? email,
    bool? isEmailVerified,
    String? visitorType,
    String? state,
    String? country,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      selectedCity: selectedCity ?? this.selectedCity,
      email: email ?? this.email,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      visitorType: visitorType ?? this.visitorType,
      state: state ?? this.state,
      country: country ?? this.country,
    );
  }
} 