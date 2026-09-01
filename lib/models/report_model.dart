class ReportModel {
  final Map<String, dynamic>? policyholder;
  final Map<String, dynamic>? caregiver;
  final String? dateOfService;
  final String? timeIn;
  final String? timeOut;
  final double? totalHours;
  final double? rate;
  final double? totalCharge;
  final Map<String, dynamic>? adls;
  final Map<String, dynamic>? iadls;
  final Map<String, dynamic>? signatures;
  final String? certification;

  ReportModel({
    this.policyholder,
    this.caregiver,
    this.dateOfService,
    this.timeIn,
    this.timeOut,
    this.totalHours,
    this.rate,
    this.totalCharge,
    this.adls,
    this.iadls,
    this.signatures,
    this.certification,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // ✅ Helper function to convert String to double safely
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // ✅ Helper function to convert dynamic to String safely
    String? parseString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    // ✅ Handle nested time_entry if present
    final timeEntry = json['time_entry'] as Map<String, dynamic>?;

    return ReportModel(
      policyholder: json['policyholder'] as Map<String, dynamic>?,
      caregiver: json['caregiver'] as Map<String, dynamic>?,
      dateOfService:
          parseString(timeEntry?['date'] ?? json['date_of_service']),
      timeIn: parseString(timeEntry?['time_in'] ?? json['time_in']),
      timeOut: parseString(timeEntry?['time_out'] ?? json['time_out']),
      totalHours:
          parseDouble(timeEntry?['total_hours'] ?? json['total_hours']),
      rate: parseDouble(timeEntry?['rate'] ?? json['rate']),
      totalCharge:
          parseDouble(timeEntry?['total_charge'] ?? json['total_charge']),
      adls: json['adls'] as Map<String, dynamic>?,
      iadls: json['iadls'] as Map<String, dynamic>?,
      signatures: json['signatures'] as Map<String, dynamic>?,
      certification: parseString(json['certification']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'policyholder': policyholder,
      'caregiver': caregiver,
      'date_of_service': dateOfService,
      'time_in': timeIn,
      'time_out': timeOut,
      'total_hours': totalHours,
      'rate': rate,
      'total_charge': totalCharge,
      'adls': adls,
      'iadls': iadls,
      'signatures': signatures,
      'certification': certification,
    };
  }
}
