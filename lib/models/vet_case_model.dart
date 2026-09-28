class RecommendedTest {
  final String id;
  final String testName;
  final String labName;
  final String status;
  final String orderedAt;

  RecommendedTest({
    required this.id,
    required this.testName,
    required this.labName,
    required this.status,
    required this.orderedAt,
  });

  factory RecommendedTest.fromJson(Map<String, dynamic> json) {
    return RecommendedTest(
      id: json['id'] ?? '',
      testName: json['testName'] ?? '',
      labName: json['labName'] ?? '',
      status: json['status'] ?? 'Sample Pending',
      orderedAt: json['orderedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'testName': testName,
        'labName': labName,
        'status': status,
        'orderedAt': orderedAt,
      };
}

class Prescription {
  final String id;
  final String medicineName;
  final String dosage;
  final String instructions;
  final int? withdrawalPeriodDays;

  Prescription({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.instructions,
    this.withdrawalPeriodDays,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] ?? '',
      medicineName: json['medicineName'] ?? '',
      dosage: json['dosage'] ?? '',
      instructions: json['instructions'] ?? '',
      withdrawalPeriodDays: json['withdrawalPeriodDays'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'instructions': instructions,
    };
    if (withdrawalPeriodDays != null) {
      map['withdrawalPeriodDays'] = withdrawalPeriodDays;
    }
    return map;
  }
}

class VetCaseModel {
  final String id;
  final String animalId;
  final String farmerId;
  final String? vetId;
  final List<String> symptoms;
  final String description;
  final List<String> photoUrls;
  final int aiRiskScore;
  final String aiPredictedDisease;
  final double aiConfidence;
  final String aiSeverity;
  final bool suspectedOutbreak;
  final String status;
  final String? vetNotes;
  final List<RecommendedTest> recommendedTests;
  final List<Prescription> prescriptions;
  final String createdAt;

  final String? displayId;
  final String? species;
  final int? ageYears;
  final String? village;
  final String? priority;
  final String? reportedAgo;
  final String? animalName;
  final String? farmerName;

  VetCaseModel({
    required this.id,
    required this.animalId,
    required this.farmerId,
    this.vetId,
    required this.symptoms,
    required this.description,
    required this.photoUrls,
    required this.aiRiskScore,
    required this.aiPredictedDisease,
    required this.aiConfidence,
    required this.aiSeverity,
    required this.suspectedOutbreak,
    required this.status,
    this.vetNotes,
    required this.recommendedTests,
    required this.prescriptions,
    required this.createdAt,
    this.displayId,
    this.species,
    this.ageYears,
    this.village,
    this.priority,
    this.reportedAgo,
    this.animalName,
    this.farmerName,
  });

  String get formattedCaseId {
    if (displayId != null && displayId!.isNotEmpty) {
      if (displayId!.toUpperCase().startsWith('Q-')) return 'TOKEN ${displayId!}';
      return displayId!;
    }
    if (id.startsWith('CASE-')) return id;
    final digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      return 'CASE-2026-${digits.substring(digits.length - 4).padLeft(6, '0')}';
    }
    return 'CASE-2026-000101';
  }


  String get speciesAndAge {
    final s = species ?? (animalId.toLowerCase().contains('buffalo') ? 'Buffalo' : 'Cow');
    final a = ageYears ?? 3;
    return '$s • $a years';
  }

  String get villageText => village ?? 'Khed, Pune';

  String get reportedAgoText {
    if (reportedAgo != null && reportedAgo!.isNotEmpty) return reportedAgo!;
    try {
      final created = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(created);
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hrs ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'Today';
    }
  }

  String get priorityText {
    if (priority != null && priority!.isNotEmpty) return priority!;
    if (aiRiskScore >= 75 || suspectedOutbreak || aiSeverity.toLowerCase() == 'critical') {
      return 'High Priority';
    }
    if (aiRiskScore >= 50 || aiSeverity.toLowerCase() == 'high' || aiSeverity.toLowerCase() == 'moderate') {
      return 'Medium';
    }
    return 'Low';
  }

  String get initials {
    if (animalName != null && animalName!.isNotEmpty) {
      final clean = animalName!.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim();
      if (clean.isNotEmpty) {
        return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
      }
    }
    if (farmerName != null && farmerName!.isNotEmpty) {
      final parts = farmerName!.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0].substring(0, 1).toUpperCase();
    }
    return 'VT';
  }

  String? get primaryPhoto {
    if (photoUrls.isNotEmpty && photoUrls.first.trim().isNotEmpty) {
      return photoUrls.first;
    }
    return null;
  }

  factory VetCaseModel.fromJson(Map<String, dynamic> json) {
    final rawCaseId = json['caseNumber'] ?? json['caseId'] ?? json['id'] ?? '';
    return VetCaseModel(
      id: rawCaseId,
      animalId: json['animalId'] ?? '',
      farmerId: json['farmerId'] ?? '',
      vetId: json['vetId'],
      symptoms: List<String>.from(json['symptoms'] ?? []),
      description: json['description'] ?? '',
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      aiRiskScore: json['aiRiskScore'] ?? 0,
      aiPredictedDisease: json['aiPredictedDisease'] ?? '',
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble() ?? 0.0,
      aiSeverity: json['aiSeverity'] ?? 'Low',
      suspectedOutbreak: json['suspectedOutbreak'] ?? false,
      status: json['status'] ?? 'reported',
      vetNotes: json['vetNotes'],
      recommendedTests: (json['recommendedTests'] as List? ?? [])
          .map((t) => RecommendedTest.fromJson(t))
          .toList(),
      prescriptions: (json['prescriptions'] as List? ?? [])
          .map((p) => Prescription.fromJson(p))
          .toList(),
      createdAt: json['createdAt'] ?? '',
      displayId: json['caseNumber'] ?? json['caseId'] ?? json['displayId'],
      species: json['species'],

      ageYears: json['ageYears'],
      village: json['village'] ?? json['district'],
      priority: json['priority'],
      reportedAgo: json['reportedAgo'],
      animalName: json['animalName'],
      farmerName: json['farmerName'],
    );
  }

  factory VetCaseModel.fromAppointment(Map<String, dynamic> json) {
    final animal = json['animal'] is Map ? json['animal'] as Map<String, dynamic> : <String, dynamic>{};
    final photos = <String>[];
    if (json['photoUrls'] is List) {
      for (final p in json['photoUrls']) {
        if (p != null && p.toString().isNotEmpty) photos.add(p.toString());
      }
    } else if (animal['photos'] is List) {
      for (final p in animal['photos']) {
        if (p != null && p.toString().isNotEmpty) photos.add(p.toString());
      }
    }

    final symptoms = <String>[];
    if (json['symptoms'] is List) {
      for (final s in json['symptoms']) {
        if (s != null && s.toString().isNotEmpty) symptoms.add(s.toString());
      }
    } else if (json['notes'] != null && json['notes'].toString().isNotEmpty) {
      symptoms.add(json['notes'].toString());
    }

    final isEmergency = json['isEmergency'] == true || json['type'] == 'emergency';
    final token = json['queueToken'] ?? json['tokenNumber'] ?? json['token'] ?? json['appointmentNumber'] ?? json['appointmentId'];

    return VetCaseModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? 'APT-${DateTime.now().millisecondsSinceEpoch}',
      animalId: json['animalTag']?.toString() ?? animal['tagNumber']?.toString() ?? 'ANM-001',
      farmerId: json['farmer']?.toString() ?? json['farmerId']?.toString() ?? 'FARMER-001',
      vetId: json['veterinarian']?.toString() ?? json['vetId']?.toString(),
      symptoms: symptoms.isEmpty ? ['General Health Examination'] : symptoms,
      description: json['description']?.toString() ?? json['notes']?.toString() ?? json['reason']?.toString() ?? 'Clinical Consultation Intake',
      photoUrls: photos,
      aiRiskScore: isEmergency ? 92 : 50,
      aiPredictedDisease: json['suspectedDisease']?.toString() ?? (isEmergency ? 'Urgent Trauma / Acute Condition' : 'Bovine Clinical Signs'),
      aiConfidence: 0.90,
      aiSeverity: isEmergency ? 'Critical' : 'Moderate',
      suspectedOutbreak: json['suspectedOutbreak'] == true,
      status: json['status']?.toString() ?? 'in_queue',
      vetNotes: json['callNotes']?.toString() ?? '',
      recommendedTests: [],
      prescriptions: [],
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      displayId: token?.toString(),
      species: animal['species']?.toString() ?? json['species']?.toString() ?? json['animalSpecies']?.toString() ?? 'Bovine',
      ageYears: animal['ageYears'] is int ? animal['ageYears'] as int : 3,
      village: json['village']?.toString() ?? 'Khed, Pune',
      farmerName: json['farmerName']?.toString() ?? 'Livestock Owner',
      animalName: json['animalName']?.toString() ?? animal['name']?.toString() ?? 'Livestock',
    );
  }
}
