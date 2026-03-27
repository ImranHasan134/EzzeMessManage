import 'package:objectbox/objectbox.dart';

@Entity()
class Member {
  @Id()
  int id = 0;
  late String name;
  late String initials;
  late String avatarColor;
  bool isActive = true;
  late String joinedMonthId;
  DateTime? createdAt;

  Member({
    this.id = 0,
    this.name = '',
    this.initials = '',
    this.avatarColor = '7F77DD',
    this.isActive = true,
    this.joinedMonthId = '',
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'initials': initials,
    'avatarColor': avatarColor,
    'isActive': isActive,
    'joinedMonthId': joinedMonthId,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Member.fromJson(Map<String, dynamic> j) => Member(
    name: j['name'] ?? '',
    initials: j['initials'] ?? '',
    avatarColor: j['avatarColor'] ?? '7F77DD',
    isActive: j['isActive'] ?? true,
    joinedMonthId: j['joinedMonthId'] ?? '',
    createdAt: j['createdAt'] != null ? DateTime.parse(j['createdAt']) : null,
  );
}