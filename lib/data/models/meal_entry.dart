import 'package:objectbox/objectbox.dart';

@Entity()
class MealEntry {
  @Id()
  int id = 0;
  late int memberId;
  late int count;
  @Property(type: PropertyType.date)
  late DateTime date;
  late String monthId;

  MealEntry({
    this.id = 0,
    this.memberId = 0,
    this.count = 0,
    DateTime? date,
    this.monthId = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'count': count,
    'date': date.toIso8601String(),
    'monthId': monthId,
  };

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
    memberId: j['memberId'] ?? 0,
    count: j['count'] ?? 0,
    date: DateTime.parse(j['date']),
    monthId: j['monthId'] ?? '',
  );
}