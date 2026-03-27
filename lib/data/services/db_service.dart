import 'package:path_provider/path_provider.dart';
import 'package:objectbox/objectbox.dart';

// Go up two levels to the root lib/ folder for the generated file
import '../../objectbox.g.dart';

// Go up one level to data/, then down into models/
import '../models/member.dart';
import '../models/meal_entry.dart';
import '../models/bazar_entry.dart';
import '../models/other_cost.dart';
import '../models/payment.dart';

class DbService {
  late Store _store;
  late Box<Member> _memberBox;
  late Box<MealEntry> _mealBox;
  late Box<BazarEntry> _bazarBox;
  late Box<OtherCost> _costBox;
  late Box<Payment> _paymentBox;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _store = await openStore(directory: '${dir.path}/mess_ob');

    _memberBox = _store.box<Member>();
    _mealBox = _store.box<MealEntry>();
    _bazarBox = _store.box<BazarEntry>();
    _costBox = _store.box<OtherCost>();
    _paymentBox = _store.box<Payment>();
  }

  List<Member> getActiveMembers() =>
      _memberBox.getAll().where((m) => m.isActive).toList();

  void saveMember(Member m) => _memberBox.put(m);

  void softDeleteMember(int id) {
    final m = _memberBox.get(id);
    if (m != null) {
      m.isActive = false;
      _memberBox.put(m);
    }
  }

  List<MealEntry> getMealsByMonth(String monthId) =>
      _mealBox.getAll().where((e) => e.monthId == monthId).toList();

  void saveMeal(MealEntry e) => _mealBox.put(e);
  void deleteMeal(int id) => _mealBox.remove(id);

  List<BazarEntry> getBazarByMonth(String monthId) =>
      _bazarBox.getAll().where((e) => e.monthId == monthId).toList();

  void saveBazar(BazarEntry e) => _bazarBox.put(e);
  void deleteBazar(int id) => _bazarBox.remove(id);

  List<OtherCost> getCostsByMonth(String monthId) =>
      _costBox.getAll().where((e) => e.monthId == monthId).toList();

  void saveCost(OtherCost e) => _costBox.put(e);
  void deleteCost(int id) => _costBox.remove(id);

  List<Payment> getPaymentsByMonth(String monthId) =>
      _paymentBox.getAll().where((e) => e.monthId == monthId).toList();

  void savePayment(Payment e) => _paymentBox.put(e);
  void deletePayment(int id) => _paymentBox.remove(id);

  List<String> getAllMonthIds() {
    final ids = _mealBox.getAll().map((e) => e.monthId).toSet().toList();
    ids.sort((a, b) => b.compareTo(a));
    return ids;
  }

  void clearMonth(String monthId) {
    final mealIds = _mealBox.getAll().where((e) => e.monthId == monthId).map((e) => e.id).toList();
    final bazarIds = _bazarBox.getAll().where((e) => e.monthId == monthId).map((e) => e.id).toList();
    final costIds = _costBox.getAll().where((e) => e.monthId == monthId).map((e) => e.id).toList();
    final payIds = _paymentBox.getAll().where((e) => e.monthId == monthId).map((e) => e.id).toList();
    _mealBox.removeMany(mealIds);
    _bazarBox.removeMany(bazarIds);
    _costBox.removeMany(costIds);
    _paymentBox.removeMany(payIds);
  }
}

// Global instance
final dbService = DbService();