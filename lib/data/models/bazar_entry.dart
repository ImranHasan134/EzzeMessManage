import 'package:objectbox/objectbox.dart';

@Entity()
class BazarEntry {
  @Id()
  int id = 0;
  late double amount;
  late String note;
  late String category;
  @Property(type: PropertyType.date)
  late DateTime date;
  late String monthId;

  BazarEntry({
    this.id = 0,
    this.amount = 0,
    this.note = '',
    this.category = 'General',
    DateTime? date,
    this.monthId = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'note': note,
    'category': category,
    'date': date.toIso8601String(),
    'monthId': monthId,
  };

  factory BazarEntry.fromJson(Map<String, dynamic> j) => BazarEntry(
    amount: (j['amount'] as num).toDouble(),
    note: j['note'] ?? '',
    category: j['category'] ?? 'General',
    date: DateTime.parse(j['date']),
    monthId: j['monthId'] ?? '',
  );
}