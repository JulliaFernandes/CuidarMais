import 'package:flutter/material.dart' show TimeOfDay;

/// Quem cadastrou o remédio (documento do projeto v2). O cadastro do
/// médico vale como referência; os outros também geram lembretes.
enum MedicationOrigin { medico, familia, paciente }

extension MedicationOriginLabel on MedicationOrigin {
  /// Como o médico e o cuidador veem a origem.
  String get label {
    switch (this) {
      case MedicationOrigin.medico:
        return 'Prescrição validada';
      case MedicationOrigin.familia:
        return 'Cadastrado pela família';
      case MedicationOrigin.paciente:
        return 'Cadastrado pelo paciente';
    }
  }
}

class Medication {
  final String id;
  final String elderId;
  String name;
  String dosage;
  List<TimeOfDay> times;

  /// Dias da semana no padrão do Dart: 1 = segunda ... 7 = domingo.
  Set<int> weekdays;
  DateTime start;
  DateTime? end;

  /// Minutos sem resposta até o cuidador ser avisado.
  int alertMinutes;
  final MedicationOrigin origin;
  final String createdByName;

  /// Toda alteração fica registrada (documento do projeto v2).
  final List<String> history;

  Medication({
    required this.id,
    required this.elderId,
    required this.name,
    required this.dosage,
    required this.times,
    required this.weekdays,
    required this.start,
    required this.origin,
    required this.createdByName,
    this.end,
    this.alertMinutes = 30,
    List<String>? history,
  }) : history = history ?? [];

  bool isActiveOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(start.year, start.month, start.day);
    if (!weekdays.contains(d.weekday) || d.isBefore(s)) return false;
    final e = end;
    if (e == null) return true;
    return !d.isAfter(DateTime(e.year, e.month, e.day));
  }

  int get firstMinuteOfDay {
    if (times.isEmpty) return 24 * 60;
    return times.map((t) => t.hour * 60 + t.minute).reduce((a, b) => a < b ? a : b);
  }
}
