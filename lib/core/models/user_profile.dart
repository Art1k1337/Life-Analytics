enum Gender { male, female, other }

extension GenderLabel on Gender {
  String get label => switch (this) {
        Gender.male => 'Мужской',
        Gender.female => 'Женский',
        Gender.other => 'Другой',
      };

  static Gender fromString(String value) => Gender.values.firstWhere(
        (g) => g.name == value,
        orElse: () => Gender.other,
      );
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
  });

  final String name;
  final double weightKg;
  final int heightCm;
  final int age;
  final Gender gender;

  Map<String, Object> toMap() => {
        'name': name,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'age': age,
        'gender': gender.name,
      };

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
        name: map['name'] as String? ?? '',
        weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
        heightCm: (map['heightCm'] as num?)?.round() ?? 0,
        age: (map['age'] as num?)?.round() ?? 0,
        gender: GenderLabel.fromString(map['gender'] as String? ?? ''),
      );
}
