class PreferenceModel {
  final int foodPreference; // 0-5
  final int attractionsPreference; // 0-3
  final int experiencesPreference; // 0-2
  final int days; // 1-3

  PreferenceModel({
    required this.foodPreference,
    required this.attractionsPreference,
    required this.experiencesPreference,
    required this.days,
  });

  factory PreferenceModel.initial() {
    return PreferenceModel(
      foodPreference: 3,
      attractionsPreference: 2,
      experiencesPreference: 1,
      days: 2,
    );
  }

  factory PreferenceModel.fromJson(Map<String, dynamic> json) {
    return PreferenceModel(
      foodPreference: json['foodPreference'] as int,
      attractionsPreference: json['attractionsPreference'] as int,
      experiencesPreference: json['experiencesPreference'] as int,
      days: json['days'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodPreference': foodPreference,
      'attractionsPreference': attractionsPreference,
      'experiencesPreference': experiencesPreference,
      'days': days,
    };
  }

  PreferenceModel copyWith({
    int? foodPreference,
    int? attractionsPreference,
    int? experiencesPreference,
    int? days,
  }) {
    return PreferenceModel(
      foodPreference: foodPreference ?? this.foodPreference,
      attractionsPreference: attractionsPreference ?? this.attractionsPreference,
      experiencesPreference: experiencesPreference ?? this.experiencesPreference,
      days: days ?? this.days,
    );
  }
} 