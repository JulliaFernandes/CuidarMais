enum DoseStatus { pendente, tomada, adiada, atrasada, perdida }

extension DoseStatusLabel on DoseStatus {
  /// Rótulo em texto, sempre exibido junto da cor e do ícone do status
  /// (WCAG 1.4.1 — a informação nunca depende só de cor).
  String get label {
    switch (this) {
      case DoseStatus.pendente:
        return 'Pendente';
      case DoseStatus.tomada:
        return 'Tomada';
      case DoseStatus.adiada:
        return 'Adiada';
      case DoseStatus.atrasada:
        return 'Atrasada';
      case DoseStatus.perdida:
        return 'Perdida';
    }
  }
}

class Dose {
  final String id;
  final String medicationName;
  final String dosageText;
  final DateTime scheduledAt;
  DoseStatus status;
  int snoozeCount;
  DateTime? confirmedAt;
  String? confirmedBy;

  Dose({
    required this.id,
    required this.medicationName,
    required this.dosageText,
    required this.scheduledAt,
    this.status = DoseStatus.pendente,
    this.snoozeCount = 0,
    this.confirmedAt,
    this.confirmedBy,
  });
}
