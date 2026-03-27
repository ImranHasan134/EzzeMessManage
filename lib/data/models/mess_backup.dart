class MessBackup {
  final String version;
  final String exportedAt;
  final String monthId;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> mealEntries;
  final List<Map<String, dynamic>> bazarEntries;
  final List<Map<String, dynamic>> otherCosts;
  final List<Map<String, dynamic>> payments;

  MessBackup({
    required this.version,
    required this.exportedAt,
    required this.monthId,
    required this.members,
    required this.mealEntries,
    required this.bazarEntries,
    required this.otherCosts,
    required this.payments,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt,
    'monthId': monthId,
    'members': members,
    'mealEntries': mealEntries,
    'bazarEntries': bazarEntries,
    'otherCosts': otherCosts,
    'payments': payments,
  };

  factory MessBackup.fromJson(Map<String, dynamic> j) => MessBackup(
    version: j['version'] ?? '1.0',
    exportedAt: j['exportedAt'] ?? '',
    monthId: j['monthId'] ?? '',
    members: List<Map<String, dynamic>>.from(j['members'] ?? []),
    mealEntries: List<Map<String, dynamic>>.from(j['mealEntries'] ?? []),
    bazarEntries: List<Map<String, dynamic>>.from(j['bazarEntries'] ?? []),
    otherCosts: List<Map<String, dynamic>>.from(j['otherCosts'] ?? []),
    payments: List<Map<String, dynamic>>.from(j['payments'] ?? []),
  );
}