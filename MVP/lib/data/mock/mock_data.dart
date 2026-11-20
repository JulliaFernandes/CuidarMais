import 'package:flutter/material.dart' show TimeOfDay;
import '../models/care_alert.dart';
import '../models/dose.dart';
import '../models/medication.dart';
import '../models/people.dart';

/// Tudo que o protótipo precisa para começar, já que ainda não há backend.
class MockSeed {
  final List<AppUser> users;
  final List<Elder> elders;
  final List<Medication> medications;
  final List<Dose> doses;
  final List<CareAlert> alerts;
  final List<Invite> invites;
  final DateTime now;

  MockSeed({
    required this.users,
    required this.elders,
    required this.medications,
    required this.doses,
    required this.alerts,
    required this.invites,
    required this.now,
  });
}

/// Dados fictícios só para validar a interface — ainda sem backend.
/// Mantém os mesmos personagens do mockup HTML (Dona Maria, Seu Antônio,
/// Carla e Dra. Helena) para dar continuidade ao protótipo.
///
/// Todas as contas usam a senha 123456.
class MockData {
  MockData._();

  static const demoPassword = '123456';

  static DateTime _today(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// A demonstração começa às 08:05: a Losartana das 08:00 acabou de tocar.
  static DateTime get demoStart => _today(8, 5);

  static List<List<DoseStatus>> _rows(String code) {
    // Cada letra é um período (manhã, tarde, noite): t = tomada,
    // a = atrasada, p = perdida. Um bloco de 3 letras por dia.
    const map = {'t': DoseStatus.tomada, 'a': DoseStatus.atrasada, 'p': DoseStatus.perdida};
    final days = code.split(' ');
    return days.map((d) => d.split('').map((c) => map[c]!).toList()).toList();
  }

  /// Dona Maria esquece a tarde com frequência — é o exemplo de "padrão
  /// de esquecimento" do documento.
  static final _mariaHistory = _rows('ttt tpt tat ttt tpt tpt ttp tat tpt ttt tpt tat ttt');
  static final _antonioHistory = _rows('pta apt ttp pap tpt atp ppt tap ptp apt tpa ptp apt');
  static final _joseHistory = _rows('ttt ttt ttt ttt ttt ttt ttt ttt ttt ttt ttt ttt ttt');
  static final _anaHistory = _rows('ttt ttt ttt tat ttt ttt ttt ttt ttt ttt ttt ttt ttt');

  static MockSeed build() {
    const maria = AppUser(
      id: 'u-maria',
      name: 'Maria Aparecida Silva',
      email: 'maria@cuidar.app',
      password: demoPassword,
      role: UserRole.idoso,
      elderId: 'e-maria',
    );
    const carla = AppUser(
      id: 'u-carla',
      name: 'Carla Silva',
      email: 'carla@cuidar.app',
      password: demoPassword,
      role: UserRole.cuidador,
    );
    const helena = AppUser(
      id: 'u-helena',
      name: 'Helena Prado',
      email: 'helena@cuidar.app',
      password: demoPassword,
      role: UserRole.medico,
      detail: 'Geriatria · CRM 123456',
    );
    const rui = AppUser(
      id: 'u-rui',
      name: 'Rui Silva',
      email: 'rui@cuidar.app',
      password: demoPassword,
      role: UserRole.cuidador,
    );
    const renata = AppUser(
      id: 'u-renata',
      name: 'Renata Andrade',
      email: 'renata@cuidar.app',
      password: demoPassword,
      role: UserRole.cuidador,
    );
    const jose = AppUser(
      id: 'u-jose',
      name: 'José Carlos Andrade',
      email: 'jose@cuidar.app',
      password: demoPassword,
      role: UserRole.idoso,
      elderId: 'e-jose',
    );
    const ana = AppUser(
      id: 'u-ana',
      name: 'Ana Lúcia Rocha',
      email: 'ana@cuidar.app',
      password: demoPassword,
      role: UserRole.idoso,
      elderId: 'e-ana',
    );

    final elders = [
      Elder(
        id: 'e-maria',
        name: 'Maria Aparecida Silva',
        nickname: 'Dona Maria',
        age: 78,
        conditions: 'Hipertensão, diabetes tipo 2',
        usesApp: true,
        phone: '(11) 98877-6655',
        links: {'u-carla': const CareLink(caregiverIs: 'Filha', elderIs: 'Mãe')},
        doctorIds: ['u-helena'],
        history: _mariaHistory,
      ),
      Elder(
        id: 'e-antonio',
        name: 'Antônio Ferreira Lima',
        nickname: 'Seu Antônio',
        age: 84,
        conditions: 'Insuficiência cardíaca',
        usesApp: false,
        phone: '(11) 3456-7788',
        links: {'u-carla': const CareLink(caregiverIs: 'Filha', elderIs: 'Pai')},
        doctorIds: ['u-helena'],
        history: _antonioHistory,
      ),
      Elder(
        id: 'e-jose',
        name: 'José Carlos Andrade',
        nickname: 'Seu José',
        age: 71,
        conditions: 'Uso de anticoagulante',
        usesApp: true,
        phone: '(11) 99123-4567',
        links: {'u-renata': const CareLink(caregiverIs: 'Esposa', elderIs: 'Marido')},
        doctorIds: ['u-helena'],
        history: _joseHistory,
      ),
      Elder(
        id: 'e-ana',
        name: 'Ana Lúcia Rocha',
        nickname: 'Dona Ana',
        age: 69,
        conditions: 'Hipotireoidismo',
        usesApp: true,
        phone: '(11) 97654-3210',
        links: {},
        doctorIds: ['u-helena'],
        history: _anaHistory,
      ),
    ];

    final everyDay = {1, 2, 3, 4, 5, 6, 7};
    final start = _today(0, 0).subtract(const Duration(days: 60));
    Medication med(String id, String elderId, String name, String dosage, List<TimeOfDay> times,
            MedicationOrigin origin, String author) =>
        Medication(
          id: id,
          elderId: elderId,
          name: name,
          dosage: dosage,
          times: times,
          weekdays: Set.of(everyDay),
          start: start,
          origin: origin,
          createdByName: author,
          history: ['Cadastrado por $author'],
        );

    final medications = [
      med('m1', 'e-maria', 'Levotiroxina 50 mcg', '1 comprimido, em jejum', [const TimeOfDay(hour: 7, minute: 0)],
          MedicationOrigin.medico, 'Dra. Helena Prado'),
      med('m2', 'e-maria', 'Losartana 50 mg', '1 comprimido', [const TimeOfDay(hour: 8, minute: 0)],
          MedicationOrigin.medico, 'Dra. Helena Prado'),
      med('m3', 'e-maria', 'Metformina 850 mg', '1 comprimido, após o almoço', [const TimeOfDay(hour: 12, minute: 30)],
          MedicationOrigin.familia, 'Carla'),
      med('m4', 'e-maria', 'Vitamina D 2.000 UI', '1 cápsula', [const TimeOfDay(hour: 20, minute: 0)],
          MedicationOrigin.paciente, 'Dona Maria'),
      med('m5', 'e-antonio', 'Furosemida 40 mg', '1 comprimido, em jejum', [const TimeOfDay(hour: 8, minute: 0)],
          MedicationOrigin.medico, 'Dra. Helena Prado'),
      med('m6', 'e-antonio', 'Carvedilol 25 mg', '1 comprimido', [const TimeOfDay(hour: 20, minute: 0)],
          MedicationOrigin.familia, 'Carla'),
      med('m7', 'e-jose', 'Varfarina 5 mg', '1 comprimido', [const TimeOfDay(hour: 7, minute: 30)],
          MedicationOrigin.medico, 'Dra. Helena Prado'),
      med('m8', 'e-ana', 'Levotiroxina 75 mcg', '1 comprimido, em jejum', [const TimeOfDay(hour: 6, minute: 30)],
          MedicationOrigin.medico, 'Dra. Helena Prado'),
    ];

    // Doses de hoje para todos os horários de cada remédio.
    final doses = <Dose>[];
    for (final m in medications) {
      for (final t in m.times) {
        doses.add(Dose(
          id: 'd-${m.id}-${t.hour}${t.minute}',
          elderId: m.elderId,
          medicationId: m.id,
          medicationName: m.name,
          dosageText: m.dosage,
          scheduledAt: _today(t.hour, t.minute),
        ));
      }
    }
    void taken(String medId, int hour, int minute, String by) {
      final d = doses.firstWhere((d) => d.medicationId == medId);
      d
        ..status = DoseStatus.tomada
        ..confirmedAt = _today(hour, minute)
        ..confirmedBy = by
        ..reminderCount = 1;
    }

    taken('m1', 7, 3, 'idoso'); // Dona Maria tomou a Levotiroxina às 07:03
    taken('m8', 6, 34, 'idoso'); // Dona Ana em dia
    // Seu José não respondeu à Varfarina das 07:30: o alerta sai sozinho
    // quando o store roda as regras de escalada (prazo de 30 minutos).

    return MockSeed(
      users: [maria, carla, helena, rui, renata, jose, ana],
      elders: elders,
      medications: medications,
      doses: doses,
      alerts: [],
      // Rui (neto) já gerou um código para acompanhar a Dona Maria.
      invites: [const Invite(code: 'RUI482', caregiverId: 'u-rui', caregiverIs: 'Neto', elderIs: 'Avó')],
      now: demoStart,
    );
  }
}
