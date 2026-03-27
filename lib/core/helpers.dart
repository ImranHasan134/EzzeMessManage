String currentMonthId() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}';
}

String formatMonthId(String id) {
  final parts = id.split('-');
  if (parts.length != 2) return id;
  const months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final m = int.tryParse(parts[1]) ?? 0;
  return '${months[m]} ${parts[0]}';
}