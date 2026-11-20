import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../../shared/utils/format.dart';
import '../mock/mock_data.dart';
import '../models/care_alert.dart';
import '../models/dose.dart';
import '../models/medication.dart';
import '../models/patient.dart';
import '../models/people.dart';

/// Estado compartilhado do protótipo: contas, idosos, remédios, doses e
/// alertas. Faz o papel do backend enquanto ele não existe, para que uma
/// ação em um perfil apareça nos outros (o idoso adia 2 vezes → o cuidador
/// recebe o alerta → o médico vê o caso em vermelho).
///
/// O relógio é simulado ([now]) para a demonstração poder "passar o tempo".
class AppStore extends ChangeNotifier {
  AppStore() {
    _load();
  }

  late List<AppUser> users;
  late List<Elder> elders;
  late List<Medication> medications;
  late List<Dose> doses;
  late List<CareAlert> alerts;
  late List<Invite> invites;
  late DateTime now;
  AppUser? currentUser;

  int _seq = 0;
  final _random = Random();

  void _load() {
    final seed = MockData.build();
    users = seed.users;
    elders = seed.elders;
    medications = seed.medications;
    doses = seed.doses;
    alerts = seed.alerts;
    invites = seed.invites;
    now = seed.now;
    _runChecks();
  }

  String _newId(String prefix) => '$prefix-${_seq++}-${_random.nextInt(1000000)}';

  // ---------------------------------------------------------------------------
  // Demonstração

  /// Volta tudo ao estado inicial, mantendo a pessoa logada se ela existir.
  void resetDemo() {
    final uid = currentUser?.id;
    _load();
    currentUser = users.where((u) => u.id == uid).firstOrNull;
    notifyListeners();
  }

  /// Avança o relógio da demonstração e roda as regras de escalada.
  void advanceClock({int minutes = 15}) {
    now = now.add(Duration(minutes: minutes));
    _runChecks();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Contas

  String? login(String email, String password) {
    final user = users.where((u) => u.email.toLowerCase() == email.trim().toLowerCase()).firstOrNull;
    if (user == null) return 'Não encontramos uma conta com esse email.';
    if (user.password != password) return 'Senha incorreta. Confira e tente de novo.';
    currentUser = user;
    notifyListeners();
    return null;
  }

  bool emailInUse(String email) => users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase());

  String? signup({required String name, required String email, required String password, required UserRole role}) {
    if (emailInUse(email)) return 'Já existe uma conta com esse email. Tente entrar.';
    String? elderId;
    if (role == UserRole.idoso) {
      elderId = _newId('e');
      final first = name.trim().split(RegExp(r'\s+')).first;
      elders.add(Elder(
        id: elderId,
        name: name.trim(),
        nickname: first,
        age: 0,
        conditions: '',
        usesApp: true,
        links: {},
        doctorIds: [],
        history: List.generate(13, (_) => List.filled(3, DoseStatus.pendente)),
      ));
    }
    final user = AppUser(
      id: _newId('u'),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      role: role,
      elderId: elderId,
    );
    users.add(user);
    currentUser = user;
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Consultas

  AppUser? userById(String id) => users.where((u) => u.id == id).firstOrNull;
  Elder elderById(String id) => elders.firstWhere((e) => e.id == id);
  Elder? elderOrNull(String id) => elders.where((e) => e.id == id).firstOrNull;
  Medication? medicationById(String id) => medications.where((m) => m.id == id).firstOrNull;

  Elder? get myElder {
    final id = currentUser?.elderId;
    return id == null ? null : elderOrNull(id);
  }

  List<Elder> eldersOfCaregiver(String userId) => elders.where((e) => e.links.containsKey(userId)).toList();
  List<Elder> patientsOfDoctor(String userId) => elders.where((e) => e.doctorIds.contains(userId)).toList();

  List<Medication> medicationsOf(String elderId) =>
      medications.where((m) => m.elderId == elderId).toList()..sort((a, b) => a.firstMinuteOfDay - b.firstMinuteOfDay);

  List<Dose> dosesOf(String elderId) =>
      doses.where((d) => d.elderId == elderId).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  /// Dose que já tocou e ainda espera confirmação.
  Dose? currentDose(String elderId) =>
      dosesOf(elderId).where((d) => d.isOpen && !d.scheduledAt.isAfter(now)).firstOrNull;

  Dose? nextDose(String elderId) => dosesOf(elderId).where((d) => d.isOpen && d.scheduledAt.isAfter(now)).firstOrNull;

  List<CareAlert> alertsFor(Iterable<String> elderIds) {
    final ids = elderIds.toSet();
    return alerts.where((a) => ids.contains(a.elderId)).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<CareAlert> openAlertsFor(Iterable<String> elderIds) => alertsFor(elderIds).where((a) => a.isOpen).toList();

  CareAlert? openAlertForDose(String doseId) => alerts.where((a) => a.doseId == doseId && a.isOpen).firstOrNull;

  bool alertedEver(String doseId) => alerts.any((a) => a.doseId == doseId);

  List<AppUser> caregiversOf(Elder e) => e.caregiverIds.map(userById).whereType<AppUser>().toList();
  List<AppUser> doctorsOf(Elder e) => e.doctorIds.map(userById).whereType<AppUser>().toList();

  /// "Carla" ou "Carla e Rui" — usado nas mensagens de alerta.
  String caregiverNames(Elder e) {
    final names = caregiversOf(e).map((u) => u.firstName).toList();
    if (names.isEmpty) return 'Seu cuidador';
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
  }

  /// "Carla (filha)" — usado no painel do médico.
  String caregiversLabel(Elder e) {
    final parts = caregiversOf(e).map((u) => '${u.firstName} (${e.links[u.id]!.caregiverIs.toLowerCase()})').toList();
    return parts.isEmpty ? 'Sem cuidador vinculado' : parts.join(', ');
  }

  String describeAlert(CareAlert a, Elder e) {
    final what = a.reason == AlertReason.adiouDuasVezes
        ? 'Adiou 2 vezes o lembrete da ${a.medicationName} das ${hhmm(a.doseTime)}'
        : 'Não respondeu ao lembrete da ${a.medicationName} das ${hhmm(a.doseTime)}';
    return '$what. ${caregiverNames(e)} recebeu o alerta.';
  }

  static DosePeriod periodOf(DateTime t) => t.hour < 12
      ? DosePeriod.manha
      : t.hour < 18
          ? DosePeriod.tarde
          : DosePeriod.noite;

  List<DoseStatus> _todayRow(Elder e) {
    final today = dosesOf(e.id);
    return DosePeriod.values.map((p) {
      final inPeriod = today.where((d) => periodOf(d.scheduledAt) == p).toList();
      if (inPeriod.isEmpty) return DoseStatus.pendente;
      if (inPeriod.any((d) => d.status == DoseStatus.perdida)) return DoseStatus.perdida;
      if (inPeriod.any((d) => d.isOpen && alertedEver(d.id))) return DoseStatus.atrasada;
      if (inPeriod.every((d) => d.isTaken)) {
        final late = inPeriod.any((d) => alertedEver(d.id) || d.snoozeCount > 0);
        return late ? DoseStatus.atrasada : DoseStatus.tomada;
      }
      return DoseStatus.pendente;
    }).toList();
  }

  /// 14 dias (mais antigo → hoje), manhã/tarde/noite.
  List<List<DoseStatus>> last14(Elder e) => [...e.history, _todayRow(e)];

  /// Resumo de cada um dos últimos 7 dias (o histórico que o cuidador vê).
  List<DoseStatus> last7Days(Elder e) {
    return last14(e).skip(7).map((day) {
      if (day.every((s) => s == DoseStatus.pendente)) return DoseStatus.pendente;
      if (day.contains(DoseStatus.perdida)) return DoseStatus.perdida;
      if (day.contains(DoseStatus.atrasada) || day.contains(DoseStatus.adiada)) return DoseStatus.atrasada;
      if (day.contains(DoseStatus.pendente)) return DoseStatus.pendente;
      return DoseStatus.tomada;
    }).toList();
  }

  PatientSummary summaryOf(Elder e) {
    final open = openAlertsFor([e.id]);
    return PatientSummary(
      id: e.id,
      name: e.name,
      age: e.age,
      conditions: e.conditions.isEmpty ? 'Sem condições informadas' : e.conditions,
      caregiverName: caregiversLabel(e),
      todayDoses: dosesOf(e.id),
      last14DaysByPeriod: last14(e),
      openAlert: open.isEmpty ? null : describeAlert(open.first, e),
      usesApp: e.usesApp,
      medications: medicationsOf(e.id),
    );
  }

  List<PatientSummary> doctorPatients() {
    final me = currentUser;
    if (me == null) return [];
    return patientsOfDoctor(me.id).map(summaryOf).toList();
  }

  // ---------------------------------------------------------------------------
  // Lembretes e escalada

  /// "Tomei". Retorna false se a dose já tinha sido confirmada — a mesma
  /// dose não pode ser confirmada duas vezes (risco de dose dobrada).
  bool confirmDose(Dose d, {required bool byCaregiver}) {
    if (d.isTaken) return false;
    d
      ..status = DoseStatus.tomada
      ..confirmedAt = now
      ..confirmedBy = byCaregiver ? 'cuidador' : 'idoso';
    for (final a in alerts.where((a) => a.doseId == d.id && a.isOpen)) {
      a.resolvedAt = now;
    }
    notifyListeners();
    return true;
  }

  /// "Me lembra em 15 min", até 2 vezes. No segundo, o cuidador é avisado.
  void snooze(Dose d) {
    if (d.isTaken || d.snoozeCount >= 2) return;
    d.snoozeCount++;
    d.reminderCount++;
    if (d.snoozeCount >= 2) {
      d.status = DoseStatus.atrasada;
      if (!alertedEver(d.id)) _raiseAlert(d, AlertReason.adiouDuasVezes);
    } else {
      d.status = DoseStatus.adiada;
    }
    notifyListeners();
  }

  /// Idoso sem app: o cuidador pede para ser lembrado de novo. Sem limite —
  /// o aviso volta a cada 15 minutos até a confirmação.
  void remindCaregiverLater(Dose d) {
    if (d.isTaken) return;
    d.status = DoseStatus.adiada;
    notifyListeners();
  }

  void _raiseAlert(Dose d, AlertReason reason) {
    alerts.add(CareAlert(
      id: _newId('a'),
      elderId: d.elderId,
      doseId: d.id,
      medicationName: d.medicationName,
      doseTime: d.scheduledAt,
      reason: reason,
      createdAt: now,
    ));
  }

  /// Regras de escalada, rodadas sempre que o relógio anda (no backend de
  /// verdade, é o agendador de tarefas a cada minuto).
  void _runChecks() {
    for (final d in doses) {
      if (!d.isOpen || d.scheduledAt.isAfter(now)) continue;
      final elder = elderOrNull(d.elderId);
      if (elder == null) continue;
      if (d.reminderCount == 0) d.reminderCount = 1;
      if (elder.usesApp) {
        // Sem resposta: o prazo conta a partir do último lembrete.
        final limit = medicationById(d.medicationId)?.alertMinutes ?? 30;
        final lastReminder = d.scheduledAt.add(Duration(minutes: 15 * d.snoozeCount));
        if (now.difference(lastReminder).inMinutes >= limit && !alertedEver(d.id)) {
          d.status = DoseStatus.atrasada;
          _raiseAlert(d, AlertReason.semResposta);
        }
      } else {
        // Idoso sem app: um aviso novo ao cuidador a cada 15 minutos.
        final count = now.difference(d.scheduledAt).inMinutes ~/ 15 + 1;
        if (count > d.reminderCount) d.reminderCount = count;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Remédios

  void addMedication({
    required Elder elder,
    required String name,
    required String dosage,
    required List<TimeOfDay> times,
    required Set<int> weekdays,
    required DateTime start,
    required DateTime? end,
    required int alertMinutes,
    required MedicationOrigin origin,
    required String authorName,
  }) {
    final m = Medication(
      id: _newId('m'),
      elderId: elder.id,
      name: name.trim(),
      dosage: dosage.trim(),
      times: List.of(times)..sort(compareTimeOfDay),
      weekdays: Set.of(weekdays),
      start: start,
      end: end,
      alertMinutes: alertMinutes,
      origin: origin,
      createdByName: authorName,
      history: ['${shortDate(now)} às ${hhmm(now)} · cadastrado por $authorName'],
    );
    medications.add(m);
    _scheduleToday(m);
    notifyListeners();
  }

  void updateMedication(
    Medication m, {
    required String name,
    required String dosage,
    required List<TimeOfDay> times,
    required Set<int> weekdays,
    required DateTime start,
    required DateTime? end,
    required int alertMinutes,
    required String editorName,
  }) {
    m
      ..name = name.trim()
      ..dosage = dosage.trim()
      ..times = (List.of(times)..sort(compareTimeOfDay))
      ..weekdays = Set.of(weekdays)
      ..start = start
      ..end = end
      ..alertMinutes = alertMinutes;
    m.history.add('${shortDate(now)} às ${hhmm(now)} · alterado por $editorName');
    // Refaz só as doses que ainda vão tocar.
    doses.removeWhere((d) => d.medicationId == m.id && d.isOpen && d.scheduledAt.isAfter(now));
    _scheduleToday(m);
    notifyListeners();
  }

  void _scheduleToday(Medication m) {
    final today = dateOnly(now);
    if (!m.isActiveOn(today)) return;
    for (final t in m.times) {
      final at = DateTime(today.year, today.month, today.day, t.hour, t.minute);
      if (!at.isAfter(now)) continue; // lembretes começam do próximo horário
      if (doses.any((d) => d.medicationId == m.id && d.scheduledAt == at)) continue;
      doses.add(Dose(
        id: _newId('d'),
        elderId: m.elderId,
        medicationId: m.id,
        medicationName: m.name,
        dosageText: m.dosage,
        scheduledAt: at,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Vínculos

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// O cuidador gera um código; o idoso digita e aceita no app dele.
  Invite createInvite({required AppUser caregiver, required String elderIs}) {
    final code = List.generate(6, (_) => _codeChars[_random.nextInt(_codeChars.length)]).join();
    final invite = Invite(code: code, caregiverId: caregiver.id, caregiverIs: 'Cuidador(a)', elderIs: elderIs);
    invites.add(invite);
    notifyListeners();
    return invite;
  }

  Invite? findInvite(String raw) {
    final code = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return invites.where((i) => i.code == code).firstOrNull;
  }

  void acceptInvite(Invite invite, Elder elder) {
    elder.links[invite.caregiverId] = CareLink(caregiverIs: invite.caregiverIs, elderIs: invite.elderIs);
    invites.remove(invite);
    notifyListeners();
  }

  void declineInvite(Invite invite) {
    invites.remove(invite);
    notifyListeners();
  }

  void removeCaregiver(Elder elder, String caregiverId) {
    elder.links.remove(caregiverId);
    notifyListeners();
  }

  Elder addElderWithoutApp({
    required AppUser caregiver,
    required String name,
    required int age,
    required String elderIs,
    String phone = '',
  }) {
    final first = name.trim().split(RegExp(r'\s+')).first;
    final elder = Elder(
      id: _newId('e'),
      name: name.trim(),
      nickname: first,
      age: age,
      conditions: '',
      usesApp: false,
      phone: phone.trim(),
      links: {caregiver.id: CareLink(caregiverIs: 'Cuidador(a)', elderIs: elderIs)},
      doctorIds: [],
      history: List.generate(13, (_) => List.filled(3, DoseStatus.pendente)),
    );
    elders.add(elder);
    notifyListeners();
    return elder;
  }

  /// Vínculo médico–paciente pelo email do paciente. A forma definitiva
  /// ainda está em aberto no backlog (AUTH-7).
  String? linkPatientByEmail(String email) {
    final me = currentUser;
    if (me == null) return 'Entre na sua conta de novo.';
    final user = users
        .where((u) => u.role == UserRole.idoso && u.email.toLowerCase() == email.trim().toLowerCase())
        .firstOrNull;
    if (user == null || user.elderId == null) {
      return 'Não encontramos um paciente com esse email. Ele precisa ter conta no app Cuidar+.';
    }
    final elder = elderById(user.elderId!);
    if (elder.doctorIds.contains(me.id)) return 'Esse paciente já está na sua lista.';
    elder.doctorIds.add(me.id);
    notifyListeners();
    return null;
  }
}
