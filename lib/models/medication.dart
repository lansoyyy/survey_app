class Medication {
  String id;
  String drugName;
  String dose;
  String time;
  DateTime? nextConsultationDate;
  String? physicianName;
  String? clinicAddress;

  Medication({
    required this.id,
    required this.drugName,
    required this.dose,
    required this.time,
    this.nextConsultationDate,
    this.physicianName,
    this.clinicAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drugName': drugName,
      'dose': dose,
      'time': time,
      'nextConsultationDate': nextConsultationDate?.toIso8601String(),
      'physicianName': physicianName,
      'clinicAddress': clinicAddress,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] ?? '',
      drugName: map['drugName'] ?? '',
      dose: map['dose'] ?? '',
      time: map['time'] ?? '',
      nextConsultationDate: map['nextConsultationDate'] != null
          ? DateTime.parse(map['nextConsultationDate'])
          : null,
      physicianName: map['physicianName'],
      clinicAddress: map['clinicAddress'],
    );
  }
}
