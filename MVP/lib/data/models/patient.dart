import 'dose.dart';
import 'medication.dart';

/// Painel por exceção do médico (PDF do projeto): vermelho, amarelo, verde.
enum AttentionLevel { critico, atencao, estavel }

/// Período do dia usado no heatmap de adesão (manhã/tarde/noite), para
/// mostrar se o paciente esquece sempre no mesmo horário.
enum DosePeriod { manha, tarde, noite }

extension DosePeriodLabel on DosePeriod {
  String get label {
    switch (this) {
      case DosePeriod.manha:
        return 'Manhã';
      case DosePeriod.tarde:
        return 'Tarde';
      case DosePeriod.noite:
        return 'Noite';
    }
  }

  String get short {
    switch (this) {
      case DosePeriod.manha:
        return 'M';
      case DosePeriod.tarde:
        return 'T';
      case DosePeriod.noite:
        return 'N';
    }
  }
}

DosePeriod periodOfTime(DateTime t) => t.hour < 12
    ? DosePeriod.manha
    : t.hour < 18
        ? DosePeriod.tarde
        : DosePeriod.noite;

/// Resume as doses de um período (manhã, tarde ou noite) de um dia em um só
/// status, para o histórico do cuidador e o heatmap do médico.
/// [alerted] são as doses que já geraram alerta ao cuidador.
DoseStatus periodStatus(List<Dose> inPeriod, Set<String> alerted) {
  if (inPeriod.isEmpty) return DoseStatus.pendente;
  if (inPeriod.any((d) => d.status == DoseStatus.perdida)) return DoseStatus.perdida;
  if (inPeriod.any((d) => d.isOpen && alerted.contains(d.id))) return DoseStatus.atrasada;
  if (inPeriod.every((d) => d.isTaken)) {
    final late = inPeriod.any((d) => alerted.contains(d.id) || d.snoozeCount > 0);
    return late ? DoseStatus.atrasada : DoseStatus.tomada;
  }
  return DoseStatus.pendente;
}

class PatientSummary {
  final String id;
  final String name;
  final int age;
  final String conditions;
  final String caregiverName;
  final List<Dose> todayDoses;
  final String? openAlert;

  /// Idoso sem app: as doses são confirmadas pelo cuidador.
  final bool usesApp;
  final List<Medication> medications;

  /// 14 dias (mais antigo → hoje), cada um com o status de manhã/tarde/noite,
  /// na mesma ordem de [DosePeriod.values]. Alimenta o anel de adesão e o
  /// heatmap do relatório do médico.
  final List<List<DoseStatus>> last14DaysByPeriod;

  PatientSummary({
    required this.id,
    required this.name,
    required this.age,
    required this.conditions,
    required this.caregiverName,
    required this.todayDoses,
    required this.last14DaysByPeriod,
    this.openAlert,
    this.usesApp = true,
    this.medications = const [],
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  List<DoseStatus> get _flatHistory => last14DaysByPeriod.expand((d) => d).toList();

  /// % de doses tomadas entre as que já deveriam ter acontecido
  /// (ignora `pendente`, que ainda não venceu).
  double get adherencePercent {
    final resolved = _flatHistory.where((s) => s != DoseStatus.pendente).toList();
    if (resolved.isEmpty) return 100;
    final taken = resolved.where((s) => s == DoseStatus.tomada).length;
    return taken / resolved.length * 100;
  }

  /// Quantas doses de cada status nos 14 dias — usado no anel (donut).
  Map<DoseStatus, int> get historyBreakdown {
    final map = {for (final s in DoseStatus.values) s: 0};
    for (final s in _flatHistory) {
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  /// Período com mais perdas/atrasos nos 14 dias, se passar de 30% —
  /// mesma regra do diferencial "detectar padrão de esquecimento" do
  /// documento do projeto. Retorna null se não houver padrão claro.
  DosePeriod? get worstPeriodPattern {
    DosePeriod? worst;
    double worstRate = 0.30; // limiar: mais de 30% de perdas no período
    for (final period in DosePeriod.values) {
      final values = last14DaysByPeriod.map((d) => d[period.index]).toList();
      final resolved = values.where((s) => s != DoseStatus.pendente).toList();
      if (resolved.isEmpty) continue;
      final ruins = resolved.where((s) => s == DoseStatus.perdida || s == DoseStatus.atrasada).length;
      final rate = ruins / resolved.length;
      if (rate > worstRate) {
        worstRate = rate;
        worst = period;
      }
    }
    return worst;
  }

  AttentionLevel get attentionLevel {
    if (openAlert != null) return AttentionLevel.critico;
    final hasDelay = todayDoses.any(
      (d) => d.status == DoseStatus.atrasada || d.status == DoseStatus.adiada,
    );
    if (hasDelay) return AttentionLevel.atencao;
    return AttentionLevel.estavel;
  }
}
