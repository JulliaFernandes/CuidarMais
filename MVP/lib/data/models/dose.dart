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

/// Uma dose concreta na agenda do dia (ex.: Losartana às 08:00 de hoje).
class Dose {
  final String id;
  final String elderId;
  final String medicationId;
  final String medicationName;
  final String dosageText;
  final DateTime scheduledAt;
  DoseStatus status;

  /// Quantas vezes o idoso tocou em "Me lembra em 15 min" (máximo 2).
  int snoozeCount;

  /// Quantas vezes o lembrete já tocou. No idoso sem app, o cuidador
  /// recebe um aviso novo a cada 15 minutos até confirmar.
  int reminderCount;

  DateTime? confirmedAt;

  /// 'idoso' ou 'cuidador' — o médico precisa distinguir no relatório.
  String? confirmedBy;

  Dose({
    required this.id,
    required this.medicationName,
    required this.dosageText,
    required this.scheduledAt,
    this.elderId = '',
    this.medicationId = '',
    this.status = DoseStatus.pendente,
    this.snoozeCount = 0,
    this.reminderCount = 0,
    this.confirmedAt,
    this.confirmedBy,
  });

  bool get isTaken => status == DoseStatus.tomada;

  /// Ainda espera confirmação (não foi tomada nem dada como perdida).
  bool get isOpen => status != DoseStatus.tomada && status != DoseStatus.perdida;
}
