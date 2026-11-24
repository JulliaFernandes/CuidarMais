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
import '../remote/local_alarms.dart';
import '../remote/remote_sync.dart';

/// Estado compartilhado do app: contas, idosos, remédios, doses e alertas.
///
/// Funciona de dois jeitos:
/// - **Demonstração** (contas `@cuidar.app`): tudo fica na memória e o
///   relógio é simulado ([now]), para a demonstração poder "passar o tempo";
/// - **Real** (contas criadas no app): os dados vêm do Firebase em tempo
///   real e o relógio é o de verdade ([isRealMode]).
///
/// Nos dois, uma ação em um perfil aparece nos outros (o idoso adia 2 vezes
/// → o cuidador recebe o alerta → o médico vê o caso em vermelho).
class AppStore extends ChangeNotifier {
  AppStore({bool useFirebase = false}) : _remote = useFirebase ? RemoteSync() : null {
    _load();
    final remote = _remote;
    if (remote != null) {
      remote.onChange = _applyRemote;
      remote.onMessage = (title, body) => onNotification?.call(title, body);
      _restore();
    }
  }

  final RemoteSync? _remote;

  /// Carregando a conta de quem já tinha entrado antes.
  bool restoring = false;

  /// Notificação que chegou com o app aberto (o app mostra na tela).
  void Function(String title, String body)? onNotification;

  /// Conta real, ligada ao Firebase (e não uma conta de demonstração).
  bool get isRealMode => _remote?.active ?? false;

  bool get notificationsOn => _remote?.notificationsOn ?? false;

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
  // Firebase

  void _applyRemote() {
    final remote = _remote;
    if (remote == null || !remote.active) return;
    users = remote.people;
    elders = remote.elders;
    medications = remote.medications;
    doses = remote.todayDoses;
    alerts = remote.alerts;
    invites = [];
    now = DateTime.now();
    currentUser = remote.me;
    notifyListeners();
    LocalAlarms.sync(_alarmPlans());
  }

  /// Alarmes para quem toma o remédio neste aparelho: o próprio idoso, ou o
  /// cuidador quando o idoso não usa o app. Próximos 2 dias, sem as doses
  /// já confirmadas. Mesmas regras do agendador.
  List<AlarmPlan> _alarmPlans() {
    final me = currentUser;
    if (me == null) return const [];
    final mine = switch (me.role) {
      UserRole.idoso => [if (myElder != null) myElder!],
      UserRole.cuidador => elders.where((e) => !e.usesApp).toList(),
      UserRole.medico => <Elder>[],
    };
    final clock = DateTime.now();
    final today = dateOnly(clock);
    final plans = <AlarmPlan>[];
    int idOf(String key) => key.hashCode & 0x7fffffff;

    for (final e in mine) {
      final byId = {for (final d in dosesOf(e.id)) d.id: d};
      for (final m in medicationsOf(e.id)) {
        for (var day = 0; day < 3; day++) {
          final date = today.add(Duration(days: day));
          if (!m.isActiveOn(date)) continue;
          for (final t in m.times) {
            final at = DateTime(date.year, date.month, date.day, t.hour, t.minute);
            final dose = byId[RemoteSync.doseId(m.id, at)];
            if (dose != null && !dose.isOpen) continue; // já tomou
            final when = e.usesApp
                // Idoso: na hora e, depois de 1 "Me lembra em 15 min", de novo.
                ? [at, if ((dose?.snoozeCount ?? 0) == 1) at.add(const Duration(minutes: 15))]
                // Sem app: avisa o cuidador a cada 15 minutos, por 2 horas.
                : [for (var k = 0; k < 8; k++) at.add(Duration(minutes: 15 * k))];
            for (final w in when) {
              if (!w.isAfter(clock)) continue;
              plans.add(AlarmPlan(
                id: idOf('${m.id}|${w.toIso8601String()}'),
                at: w,
                title: e.usesApp ? 'Hora do remédio: ${m.name}' : 'Hora do remédio de ${e.nickname}',
                body: e.usesApp
                    ? '${m.dosage} · ${hhmm(at)}. Toque para abrir e confirmar.'
                    : '${m.name} das ${hhmm(at)}. Confirme no app quando ${e.nickname} tomar.',
              ));
            }
          }
        }
      }
    }
    plans.sort((a, b) => a.at.compareTo(b.at));
    return plans;
  }

  Future<void> _restore() async {
    restoring = true;
    notifyListeners();
    try {
      final remote = _remote!;
      final ok = await remote.restore();
      if (ok) {
        _applyRemote();
        remote.enableNotifications();
      }
    } catch (e) {
      debugPrint('Não deu para retomar a sessão: $e');
    }
    restoring = false;
    notifyListeners();
  }

  /// Roda uma escrita no Firebase sem travar a tela; erros vão para o log.
  void _write(Future<void> Function() action) {
    action().catchError((Object e) => debugPrint('Erro ao salvar no Firebase: $e'));
  }

  /// Pede permissão e liga as notificações neste aparelho. Retorna uma
  /// mensagem de erro, ou null se deu certo.
  Future<String?> enableNotifications() async {
    final remote = _remote;
    if (remote == null || !remote.active) return 'Notificações só funcionam com uma conta real.';
    return remote.enableNotifications();
  }

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
    if (isRealMode) {
      _remote!.stop();
      LocalAlarms.clear(); // quem sair não recebe mais os alarmes desta conta
      _load(); // a demonstração volta ao início
    }
    currentUser = null;
    notifyListeners();
  }

  /// Entrar. Contas de demonstração ficam na memória; as outras usam o
  /// Firebase.
  Future<String?> signIn(String email, String password) async {
    final remote = _remote;
    if (remote == null || emailInUse(email)) return login(email, password);
    final error = await remote.signIn(email, password);
    if (error == null) {
      _applyRemote();
      remote.enableNotifications();
    }
    return error;
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final remote = _remote;
    if (remote == null) return signup(name: name, email: email, password: password, role: role);
    final error = await remote.signUp(name: name, email: email, password: password, role: role);
    if (error == null) {
      _applyRemote();
      remote.enableNotifications();
    }
    return error;
  }

  /// "Esqueci minha senha": o Firebase manda o email com o link.
  Future<void> sendPasswordReset(String email) async {
    await _remote?.sendPasswordReset(email);
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

  /// Quando o próximo lembrete desta dose vai tocar, ou null se não haverá
  /// outro (dose confirmada, ou o idoso já adiou 2 vezes e o cuidador foi
  /// avisado). Mesmas regras do alarme e do agendador.
  /// [snoozeCount] permite calcular logo depois de adiar, antes do banco
  /// confirmar a mudança.
  DateTime? nextReminderAt(Dose d, {int? snoozeCount}) {
    if (!d.isOpen) return null;
    final e = elderOrNull(d.elderId);
    if (e == null) return null;
    if (now.isBefore(d.scheduledAt)) return d.scheduledAt;
    if (e.usesApp) {
      final n = snoozeCount ?? d.snoozeCount;
      if (n != 1) return null; // ainda não adiou, ou já adiou 2 vezes
      final at = d.scheduledAt.add(const Duration(minutes: 15));
      return at.isAfter(now) ? at : null;
    }
    // Sem app: um aviso ao cuidador a cada 15 minutos até confirmar.
    final k = now.difference(d.scheduledAt).inMinutes ~/ 15 + 1;
    return d.scheduledAt.add(Duration(minutes: 15 * k));
  }

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

  static DosePeriod periodOf(DateTime t) => periodOfTime(t);

  List<DoseStatus> _todayRow(Elder e) {
    final today = dosesOf(e.id);
    final alerted = {for (final a in alerts) a.doseId};
    return DosePeriod.values
        .map((p) => periodStatus(today.where((d) => periodOf(d.scheduledAt) == p).toList(), alerted))
        .toList();
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
    if (isRealMode) {
      _write(() => _remote!.confirmDose(d, byCaregiver: byCaregiver));
      return true;
    }
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
    if (isRealMode) {
      _write(() => _remote!.snooze(d));
      return;
    }
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
    if (isRealMode) {
      _write(() => _remote!.remindCaregiverLater(d));
      return;
    }
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
    if (isRealMode) return; // com o Firebase, quem faz isso é o agendador
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
    if (isRealMode) {
      _write(() => _remote!.addMedication(
            elderId: elder.id,
            name: name,
            dosage: dosage,
            times: times,
            weekdays: weekdays,
            start: start,
            end: end,
            alertMinutes: alertMinutes,
            origin: origin,
            historyLine: '${shortDate(now)} às ${hhmm(now)} · cadastrado por $authorName',
          ));
      return;
    }
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
    if (isRealMode) {
      _write(() => _remote!.updateMedication(
            m,
            name: name,
            dosage: dosage,
            times: times,
            weekdays: weekdays,
            start: start,
            end: end,
            alertMinutes: alertMinutes,
            historyLine: '${shortDate(now)} às ${hhmm(now)} · alterado por $editorName',
          ));
      return;
    }
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
    final invite = Invite(
      code: code,
      caregiverId: caregiver.id,
      caregiverIs: 'Cuidador(a)',
      elderIs: elderIs,
      caregiverName: caregiver.name,
    );
    if (isRealMode) {
      _write(() => _remote!.createInvite(invite));
      return invite;
    }
    invites.add(invite);
    notifyListeners();
    return invite;
  }

  static String _cleanCode(String raw) => raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  Invite? findInvite(String raw) {
    final code = _cleanCode(raw);
    return invites.where((i) => i.code == code).firstOrNull;
  }

  /// Procura o convite no modo atual (memória ou Firebase).
  Future<Invite?> lookupInvite(String raw) async {
    if (!isRealMode) return findInvite(raw);
    final code = _cleanCode(raw);
    if (code.length != 6) return null;
    try {
      return await _remote!.findInvite(code);
    } catch (e) {
      debugPrint('Erro ao procurar o convite: $e');
      return null;
    }
  }

  void acceptInvite(Invite invite, Elder elder) {
    if (isRealMode) {
      _write(() => _remote!.acceptInvite(invite, elder));
      return;
    }
    elder.links[invite.caregiverId] = CareLink(caregiverIs: invite.caregiverIs, elderIs: invite.elderIs);
    invites.remove(invite);
    notifyListeners();
  }

  void declineInvite(Invite invite) {
    if (isRealMode) {
      _write(() => _remote!.declineInvite(invite));
      return;
    }
    invites.remove(invite);
    notifyListeners();
  }

  void removeCaregiver(Elder elder, String caregiverId) {
    if (isRealMode) {
      _write(() => _remote!.removeCaregiver(elder, caregiverId));
      return;
    }
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
    if (isRealMode) {
      final elder = _remote!.addElderWithoutApp(name: name, age: age, elderIs: elderIs, phone: phone);
      // Aparece na hora; o Firebase confirma logo em seguida.
      if (elderOrNull(elder.id) == null) elders = [...elders, elder];
      notifyListeners();
      return elder;
    }
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
      return 'Não encontramos um paciente com esse email. Ele precisa ter conta no app CuidarMais.';
    }
    final elder = elderById(user.elderId!);
    if (elder.doctorIds.contains(me.id)) return 'Esse paciente já está na sua lista.';
    elder.doctorIds.add(me.id);
    notifyListeners();
    return null;
  }

  /// Médico adiciona paciente pelo email. Com o Firebase, vira um pedido
  /// que o paciente aceita no app dele.
  Future<String?> addPatientByEmail(String email) async {
    if (!isRealMode) return linkPatientByEmail(email);
    try {
      return await _remote!.requestPatient(email);
    } catch (e) {
      debugPrint('Erro ao pedir vínculo: $e');
      return 'Não deu certo agora. Confira a internet e tente de novo.';
    }
  }

  /// Pedidos de médicos esperando o idoso aceitar.
  List<DoctorRequest> doctorRequestsFor(String elderId) => _remote?.requests[elderId] ?? const [];

  void answerDoctorRequest(Elder elder, DoctorRequest request, {required bool accept}) {
    if (!isRealMode) return;
    _write(() => _remote!.answerDoctorRequest(elder.id, request, accept: accept));
  }
}
