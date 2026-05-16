class AppCategory {
  final String? id;
  final String? name;
  final String? type;
  final String? icon;
  final bool? isSystem;
  final dynamic userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppCategory({
    this.id,
    this.name,
    this.type,
    this.icon,
    this.isSystem,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) => AppCategory(
    id: json["id"],
    name: json["name"],
    type: json["type"],
    icon: json["icon"],
    isSystem: json["is_system"],
    userId: json["user_id"],
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "type": type,
    "icon": icon,
    "is_system": isSystem,
    "user_id": userId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };

  AppCategory copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    bool? isSystem,
    dynamic userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
