/// Por que o cuidador foi avisado (regras de escalada do documento v2).
enum AlertReason { adiouDuasVezes, semResposta }

class CareAlert {
  final String id;
  final String elderId;
  final String doseId;
  final String medicationName;
  final DateTime doseTime;
  final AlertReason reason;
  final DateTime createdAt;
  DateTime? resolvedAt;

  CareAlert({
    required this.id,
    required this.elderId,
    required this.doseId,
    required this.medicationName,
    required this.doseTime,
    required this.reason,
    required this.createdAt,
    this.resolvedAt,
  });

  bool get isOpen => resolvedAt == null;
}
