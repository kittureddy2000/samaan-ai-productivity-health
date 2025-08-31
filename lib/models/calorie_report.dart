class CalorieReportData {
  final DateTime date;
  final double netCalorieDeficit;
  final double bmr;
  final double caloriesConsumed;
  final double caloriesBurned;
  final double? weight;
  final double? glasses;

  CalorieReportData({
    required this.date,
    required this.netCalorieDeficit,
    required this.bmr,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    this.weight,
    this.glasses,
  });

  factory CalorieReportData.fromJson(Map<String, dynamic> json) {
    return CalorieReportData(
      date: DateTime.parse(json['date'] as String),
      netCalorieDeficit: _safeToDouble(json['netCalorieDeficit']),
      bmr: _safeToDouble(json['bmr']),
      caloriesConsumed: _safeToDouble(json['caloriesConsumed']),
      caloriesBurned: _safeToDouble(json['caloriesBurned']),
      weight: json['weight'] != null ? _safeToDouble(json['weight']) : null,
      glasses: json['glasses'] != null ? _safeToDouble(json['glasses']) : null,
    );
  }

  static double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'netCalorieDeficit': netCalorieDeficit,
      'bmr': bmr,
      'caloriesConsumed': caloriesConsumed,
      'caloriesBurned': caloriesBurned,
      'weight': weight,
      'glasses': glasses,
    };
  }
}

class CalorieReport {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final List<CalorieReportData> data;
  final double averageBMR;
  final double totalCaloriesConsumed;
  final double totalCaloriesBurned;
  final double totalNetDeficit;
  final double totalGlasses;
  final double averageGlasses;
  final int daysWithData;
  final int totalDays;

  CalorieReport({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.averageBMR,
    required this.totalCaloriesConsumed,
    required this.totalCaloriesBurned,
    required this.totalNetDeficit,
    required this.totalGlasses,
    required this.averageGlasses,
    required this.daysWithData,
    required this.totalDays,
  });

  factory CalorieReport.fromJson(Map<String, dynamic> json) {
    return CalorieReport(
      period: json['period'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) =>
              CalorieReportData.fromJson(item as Map<String, dynamic>))
          .toList(),
      averageBMR: CalorieReportData._safeToDouble(json['averageBMR']),
      totalCaloriesConsumed:
          CalorieReportData._safeToDouble(json['totalCaloriesConsumed']),
      totalCaloriesBurned:
          CalorieReportData._safeToDouble(json['totalCaloriesBurned']),
      totalNetDeficit: CalorieReportData._safeToDouble(json['totalNetDeficit']),
      totalGlasses: CalorieReportData._safeToDouble(json['totalGlasses']),
      averageGlasses: CalorieReportData._safeToDouble(json['averageGlasses']),
      daysWithData: _safeToInt(json['daysWithData']),
      totalDays: _safeToInt(json['totalDays']),
    );
  }

  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'data': data.map((item) => item.toJson()).toList(),
      'averageBMR': averageBMR,
      'totalCaloriesConsumed': totalCaloriesConsumed,
      'totalCaloriesBurned': totalCaloriesBurned,
      'totalNetDeficit': totalNetDeficit,
      'totalGlasses': totalGlasses,
      'averageGlasses': averageGlasses,
      'daysWithData': daysWithData,
      'totalDays': totalDays,
    };
  }
}
