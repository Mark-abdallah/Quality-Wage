class Entry {
  final int? id;
  final String date; // ISO yyyy-MM-dd
  final String project;
  final String technician;
  final double salary;
  final double downPayment;

  const Entry({
    this.id,
    required this.date,
    required this.project,
    required this.technician,
    required this.salary,
    required this.downPayment,
  });

  double get rest => salary - downPayment;

  Entry copyWith({
    int? id,
    String? date,
    String? project,
    String? technician,
    double? salary,
    double? downPayment,
  }) {
    return Entry(
      id: id ?? this.id,
      date: date ?? this.date,
      project: project ?? this.project,
      technician: technician ?? this.technician,
      salary: salary ?? this.salary,
      downPayment: downPayment ?? this.downPayment,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date,
        'project': project,
        'technician': technician,
        'salary': salary,
        'downPayment': downPayment,
      };

  factory Entry.fromMap(Map<String, Object?> map) => Entry(
        id: map['id'] as int?,
        date: map['date'] as String,
        project: (map['project'] as String?) ?? '',
        technician: (map['technician'] as String?) ?? '',
        salary: (map['salary'] as num?)?.toDouble() ?? 0,
        downPayment: (map['downPayment'] as num?)?.toDouble() ?? 0,
      );
}
