import 'package:objectbox/objectbox.dart';

@Entity()
class OtherCost {
  @Id()
  int id = 0;
  late int memberId;
  late double amount;
  late String category;
  late String note;
  @Property(type: PropertyType.date)
  late DateTime date;
  late String monthId;

  OtherCost({
    this.id = 0,
    this.memberId = 0,
    this.amount = 0,
    this.category = 'Rent',
    this.note = '',
    DateTime? date,
    this.monthId = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'amount': amount,
    'category': category,
    'note': note,
    'date': date.toIso8601String(),
    'monthId': monthId,
  };

  factory OtherCost.fromJson(Map<String, dynamic> j) => OtherCost(
    memberId: j['memberId'] ?? 0,
    amount: (j['amount'] as num).toDouble(),
    category: j['category'] ?? 'Rent',
    note: j['note'] ?? '',
    date: DateTime.parse(j['date']),
    monthId: j['monthId'] ?? '',
  );
}