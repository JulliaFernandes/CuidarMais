import '../models/dose.dart';
import '../models/patient.dart';

/// Dados fictícios só para validar a interface — ainda sem backend.
/// Mantém os mesmos personagens do mockup HTML (Dona Maria, Carla, Dra.
/// Helena) para dar continuidade ao protótipo.
class MockData {
  MockData._();

  static DateTime _today(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static List<Dose> todayDosesForMaria() => [
        Dose(
          id: 'd1',
          medicationName: 'Levotiroxina 50 mcg',
          dosageText: '1 comprimido, em jejum',
          scheduledAt: _today(7, 0),
          status: DoseStatus.tomada,
          confirmedAt: _today(7, 3),
          confirmedBy: 'idoso',
        ),
        Dose(
          id: 'd2',
          medicationName: 'Losartana 50 mg',
          dosageText: '1 comprimido',
          scheduledAt: _today(8, 0),
        ),
        Dose(
          id: 'd3',
          medicationName: 'Metformina 850 mg',
          dosageText: '1 comprimido, após o almoço',
          scheduledAt: _today(12, 30),
        ),
      ];

  /// 14 linhas (manhã/tarde/noite). Dona Maria esquece a tarde com
  /// frequência — é o exemplo de "padrão de esquecimento" do documento.
  static const _mariaHistory = <List<DoseStatus>>[
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.perdida, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.atrasada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.perdida, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.perdida, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.perdida],
    [DoseStatus.tomada, DoseStatus.atrasada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.perdida, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.perdida, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.atrasada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    // hoje: manhã já tomada, tarde pendente (a Losartana das 08:00 do
    // mockup é tratada como "manhã" aqui), noite ainda não chegou
    [DoseStatus.tomada, DoseStatus.pendente, DoseStatus.pendente],
  ];

  static const _joseHistory = <List<DoseStatus>>[
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.pendente, DoseStatus.pendente],
  ];

  static const _antonioHistory = <List<DoseStatus>>[
    [DoseStatus.perdida, DoseStatus.tomada, DoseStatus.atrasada],
    [DoseStatus.atrasada, DoseStatus.perdida, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.tomada, DoseStatus.perdida],
    [DoseStatus.perdida, DoseStatus.atrasada, DoseStatus.perdida],
    [DoseStatus.tomada, DoseStatus.perdida, DoseStatus.tomada],
    [DoseStatus.atrasada, DoseStatus.tomada, DoseStatus.perdida],
    [DoseStatus.perdida, DoseStatus.perdida, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.atrasada, DoseStatus.perdida],
    [DoseStatus.perdida, DoseStatus.tomada, DoseStatus.perdida],
    [DoseStatus.atrasada, DoseStatus.perdida, DoseStatus.tomada],
    [DoseStatus.tomada, DoseStatus.perdida, DoseStatus.atrasada],
    [DoseStatus.perdida, DoseStatus.tomada, DoseStatus.perdida],
    [DoseStatus.atrasada, DoseStatus.perdida, DoseStatus.tomada],
    [DoseStatus.perdida, DoseStatus.pendente, DoseStatus.pendente],
  ];

  static List<PatientSummary> patients() => [
        PatientSummary(
          id: 'p1',
          name: 'Maria Aparecida Silva',
          age: 78,
          conditions: 'Hipertensão, diabetes tipo 2',
          caregiverName: 'Carla (filha)',
          last14DaysByPeriod: _mariaHistory,
          todayDoses: todayDosesForMaria(),
          openAlert: 'Não confirmou a Losartana das 08:00 — 35 minutos sem resposta.',
        ),
        PatientSummary(
          id: 'p2',
          name: 'José Carlos Andrade',
          age: 71,
          conditions: 'Uso de anticoagulante',
          caregiverName: 'Renata (esposa)',
          last14DaysByPeriod: _joseHistory,
          todayDoses: [
            Dose(
              id: 'd4',
              medicationName: 'Varfarina 5 mg',
              dosageText: '1 comprimido',
              scheduledAt: _today(9, 0),
              status: DoseStatus.tomada,
              confirmedAt: _today(9, 1),
              confirmedBy: 'idoso',
            ),
          ],
        ),
        PatientSummary(
          id: 'p3',
          name: 'Antônio Ferreira Lima',
          age: 84,
          conditions: 'Insuficiência cardíaca',
          caregiverName: 'Paulo (filho)',
          last14DaysByPeriod: _antonioHistory,
          todayDoses: [
            Dose(id: 'd5', medicationName: 'Furosemida 40 mg', dosageText: '1 comprimido', scheduledAt: _today(8, 0), status: DoseStatus.perdida),
            Dose(id: 'd6', medicationName: 'Carvedilol 25 mg', dosageText: '1 comprimido', scheduledAt: _today(20, 0)),
          ],
          openAlert: 'Duas doses seguidas sem confirmação esta semana.',
        ),
      ];
}
