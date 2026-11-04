import 'dose.dart';

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

class PatientSummary {
  final String id;
  final String name;
  final int age;
  final String conditions;
  final String caregiverName;
  final List<Dose> todayDoses;
  final String? openAlert;

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
