class ExamDocumentRequirement {
  final String? id;
  final String name;
  final bool required;

  const ExamDocumentRequirement({
    this.id,
    required this.name,
    this.required = true,
  });

  factory ExamDocumentRequirement.fromMap(Map<String, dynamic> map) {
    return ExamDocumentRequirement(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      required: map['required'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null && id!.isNotEmpty) 'id': int.tryParse(id!) ?? id,
    'name': name,
    'required': required,
  };
}

class ExamClassConfig {
  final String classroomId;
  final String classroomName;
  final String examName;
  final double officialFee;
  final List<ExamDocumentRequirement> documents;

  const ExamClassConfig({
    required this.classroomId,
    required this.classroomName,
    required this.examName,
    required this.officialFee,
    required this.documents,
  });

  factory ExamClassConfig.fromMap(Map<String, dynamic> map) {
    final documents = map['documents'] is List
        ? (map['documents'] as List)
              .whereType<Map>()
              .map(
                (item) => ExamDocumentRequirement.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <ExamDocumentRequirement>[];
    return ExamClassConfig(
      classroomId: map['classroomId']?.toString() ?? '',
      classroomName: map['classroomName']?.toString() ?? '',
      examName: map['examName']?.toString() ?? '',
      officialFee: map['officialFee'] is num
          ? (map['officialFee'] as num).toDouble()
          : double.tryParse('${map['officialFee']}') ?? 0,
      documents: documents,
    );
  }

  Map<String, dynamic> toMap() => {
    'examName': examName,
    'officialFee': officialFee,
    'documents': documents.map((item) => item.toMap()).toList(),
  };
}

class StudentExamDocument {
  final String requirementId;
  final String name;
  final bool required;
  final bool submitted;

  const StudentExamDocument({
    required this.requirementId,
    required this.name,
    required this.required,
    required this.submitted,
  });

  StudentExamDocument copyWith({bool? submitted}) => StudentExamDocument(
    requirementId: requirementId,
    name: name,
    required: required,
    submitted: submitted ?? this.submitted,
  );

  factory StudentExamDocument.fromMap(Map<String, dynamic> map) {
    return StudentExamDocument(
      requirementId: map['requirementId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      required: map['required'] == true,
      submitted: map['submitted'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'requirementId': int.tryParse(requirementId) ?? requirementId,
    'submitted': submitted,
  };
}

class StudentExamStatus {
  final String studentId;
  final String studentName;
  final double officialFee;
  final double paidAmount;
  final bool feesComplete;
  final bool dossierComplete;
  final List<StudentExamDocument> documents;

  const StudentExamStatus({
    required this.studentId,
    required this.studentName,
    required this.officialFee,
    required this.paidAmount,
    required this.feesComplete,
    required this.dossierComplete,
    required this.documents,
  });

  factory StudentExamStatus.fromMap(Map<String, dynamic> map) {
    final documents = map['documents'] is List
        ? (map['documents'] as List)
              .whereType<Map>()
              .map(
                (item) => StudentExamDocument.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <StudentExamDocument>[];
    return StudentExamStatus(
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      officialFee: _number(map['officialFee']),
      paidAmount: _number(map['paidAmount']),
      feesComplete: map['feesComplete'] == true,
      dossierComplete: map['dossierComplete'] == true,
      documents: documents,
    );
  }

  StudentExamStatus copyWith({
    double? paidAmount,
    List<StudentExamDocument>? documents,
  }) {
    final nextDocuments = documents ?? this.documents;
    return StudentExamStatus(
      studentId: studentId,
      studentName: studentName,
      officialFee: officialFee,
      paidAmount: paidAmount ?? this.paidAmount,
      feesComplete: (paidAmount ?? this.paidAmount) >= officialFee,
      dossierComplete: nextDocuments
          .where((item) => item.required)
          .every((item) => item.submitted),
      documents: nextDocuments,
    );
  }

  Map<String, dynamic> toMap() => {
    'paidAmount': paidAmount,
    'documents': documents.map((item) => item.toMap()).toList(),
  };
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}
