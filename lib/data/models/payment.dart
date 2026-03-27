import 'package:objectbox/objectbox.dart';

@Entity()
class Payment {
  @Id()
  int id = 0;
  late int memberId;
  late double amount;
  late String method;
  late String note;
  @Property(type: PropertyType.date)
  late DateTime date;
  late String monthId;

  Payment({
    this.id = 0,
    this.memberId = 0,
    this.amount = 0,
    this.method = 'Cash',
    this.note = '',
    DateTime? date,
    this.monthId = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'amount': amount,
    'method': method,
    'note': note,
    'date': date.toIso8601String(),
    'monthId': monthId,
  };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    memberId: j['memberId'] ?? 0,
    amount: (j['amount'] as num).toDouble(),
    method: j['method'] ?? 'Cash',
    note: j['note'] ?? '',
    date: DateTime.parse(j['date']),
    monthId: j['monthId'] ?? '',
  );
}