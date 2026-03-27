import '../data/models/member.dart';
import '../data/services/db_service.dart';

class MemberSummary {
  final Member member;
  final int totalMeals;
  final double mealCost;
  final double otherCosts;
  final double totalCost;
  final double paid;
  final double due;

  MemberSummary({
    required this.member,
    required this.totalMeals,
    required this.mealCost,
    required this.otherCosts,
    required this.totalCost,
    required this.paid,
    required this.due,
  });

  bool get isSettled => due.abs() < 0.01;
  bool get isOverpaid => due < -0.01;
  bool get hasDue => due > 0.01;
}

class MonthSummary {
  final double totalBazar;
  final int totalMeals;
  final double mealRate;
  final double totalPaid;
  final double totalOtherCosts;
  final double bazarBudget;
  final double bazarRemaining;
  final double totalDue;
  final List<MemberSummary> members;

  MonthSummary({
    required this.totalBazar,
    required this.totalMeals,
    required this.mealRate,
    required this.totalPaid,
    required this.totalOtherCosts,
    required this.bazarBudget,
    required this.bazarRemaining,
    required this.totalDue,
    required this.members,
  });
}

MonthSummary computeSummary(String monthId) {
  final members = dbService.getActiveMembers();
  final meals = dbService.getMealsByMonth(monthId);
  final bazar = dbService.getBazarByMonth(monthId);
  final costs = dbService.getCostsByMonth(monthId);
  final payments = dbService.getPaymentsByMonth(monthId);

  final totalBazar = bazar.fold(0.0, (s, b) => s + b.amount);
  final totalMeals = meals.fold(0, (s, m) => s + m.count);
  final mealRate = totalMeals > 0 ? totalBazar / totalMeals : 0.0;
  final totalPaid = payments.fold(0.0, (s, p) => s + p.amount);
  final totalOtherCosts = costs.fold(0.0, (s, c) => s + c.amount);
  final bazarBudget = totalPaid - totalOtherCosts;
  final bazarRemaining = bazarBudget - totalBazar;

  final summaries = members.map((member) {
    final mCount = meals.where((m) => m.memberId == member.id).fold(0, (s, m) => s + m.count);
    final mCost = mCount * mealRate;
    final oCost = costs.where((c) => c.memberId == member.id).fold(0.0, (s, c) => s + c.amount);
    final paidAmt = payments.where((p) => p.memberId == member.id).fold(0.0, (s, p) => s + p.amount);
    return MemberSummary(
      member: member,
      totalMeals: mCount,
      mealCost: mCost,
      otherCosts: oCost,
      totalCost: mCost + oCost,
      paid: paidAmt,
      due: mCost + oCost - paidAmt,
    );
  }).toList();

  return MonthSummary(
    totalBazar: totalBazar,
    totalMeals: totalMeals,
    mealRate: mealRate,
    totalPaid: totalPaid,
    totalOtherCosts: totalOtherCosts,
    bazarBudget: bazarBudget,
    bazarRemaining: bazarRemaining,
    totalDue: summaries.where((s) => s.hasDue).fold(0.0, (s, m) => s + m.due),
    members: summaries,
  );
}