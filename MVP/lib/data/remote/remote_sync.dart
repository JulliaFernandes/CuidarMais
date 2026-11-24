import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../core/config.dart';
import '../models/care_alert.dart';
import '../models/dose.dart';
import '../models/medication.dart';
import '../models/patient.dart';
import '../models/people.dart';

// O agendador (Python, firebase-admin) envia para o token do FCM. A forma
// nova do plugin (register/onRegistered) usa outro tipo de endereço, que o
// firebase-admin ainda não usa; por isso ficamos com getToken por enquanto.
// ignore_for_file: deprecated_member_use

/// Liga o app ao Firebase: login (Auth), dados em tempo real (Firestore) e
/// notificações (Cloud Messaging).
///
/// Estrutura no Firestore (detalhes em docs/modelo-de-dados.md):
/// - `usuarios/{uid}`: conta de cada pessoa e os tokens de notificação;
/// - `emails/{email}`: para o médico achar o paciente pelo email;
/// - `convites/{codigo}`: código que o cuidador gera e o idoso aceita;
/// - `idosos/{id}`: dados do idoso, com quem pode ver (`cuidadoresIds`,
///   `medicosIds`) e as subcoleções `medicamentos`, `doses`, `alertas` e
///   `pedidosMedico`.
///
/// Lembretes e alertas de "sem resposta" são enviados pelo agendador
/// (pasta `agendador/` do repositório), que roda a cada 5 minutos.
class RemoteSync {
  /// Chamado sempre que algo muda no banco.
  VoidCallback? onChange;

  /// Notificação recebida com o app aberto na tela.
  void Function(String title, String body)? onMessage;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? uid;
  AppUser? me;
  bool notificationsOn = false;

  List<AppUser> people = [];
  List<Elder> elders = [];
  List<Medication> medications = [];
  List<Dose> todayDoses = [];
  List<CareAlert> alerts = [];
  Map<String, List<DoctorRequest>> requests = {};

  final _elderDocs = <String, Map<String, dynamic>>{};
  final _meds = <String, List<Medication>>{};
  final _doses = <String, List<Dose>>{};
  final _alerts = <String, List<CareAlert>>{};
  final _requests = <String, List<DoctorRequest>>{};
  final _elderSubs = <String, List<StreamSubscription<dynamic>>>{};
  final _subs = <StreamSubscription<dynamic>>[];
  Timer? _clock;

  bool get active => uid != null;

  // ---------------------------------------------------------------------------
  // Conta

  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return await start(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    }
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    }
    final u = cred.user!.uid;
    final mail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final batch = _db.batch();
    String? elderId;
    if (role == UserRole.idoso) {
      final ref = _db.collection('idosos').doc();
      elderId = ref.id;
      batch.set(ref, {
        'usuarioId': u,
        'nome': cleanName,
        'apelido': cleanName.split(RegExp(r'\s+')).first,
        'idade': 0,
        'condicoes': '',
        'telefone': '',
        'usaApp': true,
        'cuidadoresIds': <String>[],
        'vinculos': <String, dynamic>{},
        'medicosIds': <String>[],
        'medicos': <String, dynamic>{},
        'fusoHorario': 'America/Sao_Paulo',
        'criadoPor': u,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
    batch.set(_db.collection('usuarios').doc(u), {
      'nome': cleanName,
      'email': mail,
      'perfil': role.name,
      'idosoId': elderId,
      'tokensFcm': <String>[],
      'consentimentoLgpd': {'versao': '2026-11', 'aceitoEm': FieldValue.serverTimestamp()},
      'criadoEm': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('emails').doc(mail), {'uid': u, 'perfil': role.name, 'idosoId': elderId});
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Erro ao salvar o cadastro: $e');
      await cred.user!.delete().catchError((_) {});
      return 'Não conseguimos salvar sua conta. Confira a internet e tente de novo.';
    }
    return start(u);
  }

  /// Manda o email de "criar uma senha nova". Não diz se a conta existe.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.setLanguageCode('pt-BR');
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint('Recuperar senha: ${e.code}');
    }
  }

  /// Quem já entrou antes continua logado ao abrir o app de novo.
  Future<bool> restore() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return await start(user.uid) == null;
  }

  Future<String?> start(String u) async {
    final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _db.collection('usuarios').doc(u).get();
    } catch (e) {
      return 'Não conseguimos carregar sua conta. Confira a internet e tente de novo.';
    }
    if (!snap.exists) {
      await _auth.signOut();
      return 'Essa conta não terminou o cadastro. Crie a conta de novo com outro email.';
    }
    uid = u;
    me = _userFrom(u, snap.data()!);

    _subs.add(_db.collection('usuarios').doc(u).snapshots().listen((s) {
      if (!s.exists) return;
      me = _userFrom(u, s.data()!);
      _rebuild();
    }));

    final col = _db.collection('idosos');
    final query = switch (me!.role) {
      UserRole.idoso => col.where('usuarioId', isEqualTo: u),
      UserRole.cuidador => col.where('cuidadoresIds', arrayContains: u),
      UserRole.medico => col.where('medicosIds', arrayContains: u),
    };
    final firstLoad = Completer<void>();
    _subs.add(query.snapshots().listen((s) {
      final ids = <String>{};
      for (final d in s.docs) {
        ids.add(d.id);
        _elderDocs[d.id] = d.data();
        _watchElder(d.id);
      }
      for (final gone in _elderDocs.keys.where((k) => !ids.contains(k)).toList()) {
        _unwatchElder(gone);
      }
      _rebuild();
      if (!firstLoad.isCompleted) firstLoad.complete();
    }, onError: (Object e) {
      debugPrint('Erro ao ler idosos: $e');
      if (!firstLoad.isCompleted) firstLoad.complete();
    }));

    _subs.add(FirebaseMessaging.onMessage.listen((m) {
      onMessage?.call(m.notification?.title ?? 'CuidarMais', m.notification?.body ?? '');
    }));

    // O relógio anda sozinho: a dose das 08:00 aparece quando dá 08:00.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => _rebuild());
    await firstLoad.future.timeout(const Duration(seconds: 10), onTimeout: () {});
    return null;
  }

  Future<void> stop() async {
    // Desliga tudo NA HORA, antes de qualquer espera. Se não, uma atualização
    // do banco que chegasse no meio do caminho colocaria a conta de volta na
    // tela, e era preciso tocar em "Sair" duas vezes.
    final u = uid;
    final hadNotifications = notificationsOn;
    uid = null;
    me = null;
    notificationsOn = false;
    _clock?.cancel();
    final subs = List.of(_subs);
    _subs.clear();
    for (final id in _elderDocs.keys.toList()) {
      _unwatchElder(id);
    }
    people = [];
    elders = [];
    medications = [];
    todayDoses = [];
    alerts = [];
    requests = {};
    for (final s in subs) {
      await s.cancel();
    }

    // Este aparelho para de receber as notificações dessa conta.
    if (u != null && hadNotifications) {
      try {
        final token = await FirebaseMessaging.instance.getToken(vapidKey: kIsWeb ? kWebPushKey : null);
        if (token != null) {
          await _db.collection('usuarios').doc(u).update({'tokensFcm': FieldValue.arrayRemove([token])});
        }
      } catch (_) {}
    }
    await _auth.signOut();
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email ou senha incorretos. Confira e tente de novo.';
      case 'invalid-email':
        return 'Esse email não parece válido. Confira se digitou certo.';
      case 'email-already-in-use':
        return 'Já existe uma conta com esse email. Volte e toque em "Entrar".';
      case 'weak-password':
        return 'Essa senha é fácil de adivinhar. Use pelo menos 6 caracteres, misturando letras e números.';
      case 'too-many-requests':
        return 'Muitas tentativas seguidas. Espere alguns minutos e tente de novo.';
      case 'network-request-failed':
        return 'Sem internet. Confira a conexão e tente de novo.';
      case 'operation-not-allowed':
        return 'O login por email ainda não foi ligado no Firebase.';
      default:
        return 'Não deu certo agora (${e.code}). Tente de novo em instantes.';
    }
  }

  // ---------------------------------------------------------------------------
  // Notificações

  /// Pede permissão e guarda o endereço deste aparelho para o agendador
  /// mandar os lembretes. Retorna uma mensagem de erro, ou null se deu certo.
  Future<String?> enableNotifications() async {
    final u = uid;
    if (u == null) return 'Entre na sua conta primeiro.';
    if (kIsWeb && kWebPushKey.isEmpty) {
      return 'As notificações no navegador ainda não foram configuradas (falta a chave de Web Push).';
    }
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return 'As notificações estão bloqueadas. Libere nas configurações do navegador ou do celular.';
      }
      final token = await messaging.getToken(vapidKey: kIsWeb ? kWebPushKey : null);
      if (token == null) return 'Não conseguimos ativar as notificações neste aparelho.';
      await _saveToken(token);
      _subs.add(messaging.onTokenRefresh.listen(_saveToken));
      notificationsOn = true;
      onChange?.call();
      return null;
    } catch (e) {
      debugPrint('Erro ao ativar notificações: $e');
      return 'Não conseguimos ativar as notificações neste aparelho.';
    }
  }

  Future<void> _saveToken(String token) async {
    final u = uid;
    if (u == null) return;
    await _db.collection('usuarios').doc(u).update({'tokensFcm': FieldValue.arrayUnion([token])});
  }

  // ---------------------------------------------------------------------------
  // Leitura

  void _watchElder(String id) {
    if (_elderSubs.containsKey(id)) return;
    final ref = _elderRef(id);
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 13));
    final subs = <StreamSubscription<dynamic>>[
      ref.collection('medicamentos').snapshots().listen((s) {
        _meds[id] = [
          for (final d in s.docs)
            if (d.data()['encerradoEm'] == null) _medFrom(id, d.id, d.data()),
        ];
        _rebuild();
      }, onError: _logError),
      ref
          .collection('doses')
          .where('agendadaPara', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .snapshots()
          .listen((s) {
        _doses[id] = [for (final d in s.docs) _doseFrom(id, d.id, d.data())];
        _rebuild();
      }, onError: _logError),
      ref.collection('alertas').snapshots().listen((s) {
        _alerts[id] = [for (final d in s.docs) _alertFrom(id, d.id, d.data())];
        _rebuild();
      }, onError: _logError),
    ];
    // Só o próprio idoso aceita (ou recusa) o pedido de um médico.
    if (me?.role == UserRole.idoso) {
      subs.add(ref.collection('pedidosMedico').snapshots().listen((s) {
        _requests[id] = [
          for (final d in s.docs)
            DoctorRequest(
              doctorId: d.id,
              name: (d.data()['nome'] as String?) ?? 'Médico(a)',
              detail: d.data()['detalhe'] as String?,
            ),
        ];
        _rebuild();
      }, onError: _logError));
    }
    _elderSubs[id] = subs;
  }

  void _unwatchElder(String id) {
    for (final s in _elderSubs.remove(id) ?? const <StreamSubscription<dynamic>>[]) {
      s.cancel();
    }
    _elderDocs.remove(id);
    _meds.remove(id);
    _doses.remove(id);
    _alerts.remove(id);
    _requests.remove(id);
  }

  void _logError(Object e) => debugPrint('Erro ao ler o Firestore: $e');

  void _rebuild() {
    if (uid == null) return; // saiu da conta: ignora o que ainda chegar do banco
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    alerts = _alerts.values.expand((a) => a).toList();
    final alerted = {for (final a in alerts) a.doseId};
    elders = [
      for (final e in _elderDocs.entries) _elderFrom(e.key, e.value, _doses[e.key] ?? const [], alerted, today),
    ];
    medications = _meds.values.expand((m) => m).toList();
    todayDoses = _doses.values
        .expand((d) => d)
        .where((d) => !d.scheduledAt.isBefore(today) && d.scheduledAt.isBefore(tomorrow))
        .toList();
    requests = Map.of(_requests);

    final byId = <String, AppUser>{};
    for (final e in _elderDocs.entries) {
      final d = e.value;
      final owner = d['usuarioId'] as String?;
      if (owner != null) {
        byId[owner] = AppUser(
          id: owner,
          name: (d['nome'] as String?) ?? '',
          email: '',
          password: '',
          role: UserRole.idoso,
          elderId: e.key,
        );
      }
      final links = Map<String, dynamic>.from((d['vinculos'] as Map?) ?? const {});
      for (final l in links.entries) {
        final v = Map<String, dynamic>.from(l.value as Map);
        byId[l.key] = AppUser(
          id: l.key,
          name: (v['nome'] as String?) ?? 'Cuidador(a)',
          email: '',
          password: '',
          role: UserRole.cuidador,
        );
      }
      final doctors = Map<String, dynamic>.from((d['medicos'] as Map?) ?? const {});
      for (final m in doctors.entries) {
        final v = Map<String, dynamic>.from(m.value as Map);
        byId[m.key] = AppUser(
          id: m.key,
          name: (v['nome'] as String?) ?? 'Médico(a)',
          email: '',
          password: '',
          role: UserRole.medico,
          detail: v['detalhe'] as String?,
        );
      }
    }
    if (me != null) byId[me!.id] = me!;
    people = byId.values.toList();
    onChange?.call();
  }

  // ---------------------------------------------------------------------------
  // Conversão

  AppUser _userFrom(String id, Map<String, dynamic> d) => AppUser(
        id: id,
        name: (d['nome'] as String?) ?? '',
        email: (d['email'] as String?) ?? '',
        password: '',
        role: UserRole.values.byName((d['perfil'] as String?) ?? 'cuidador'),
        elderId: d['idosoId'] as String?,
        detail: d['detalhe'] as String?,
      );

  Elder _elderFrom(String id, Map<String, dynamic> d, List<Dose> doses, Set<String> alerted, DateTime today) {
    final name = (d['nome'] as String?) ?? '';
    final links = Map<String, dynamic>.from((d['vinculos'] as Map?) ?? const {});
    final history = [
      for (var i = 13; i >= 1; i--)
        () {
          final day = today.subtract(Duration(days: i));
          final next = day.add(const Duration(days: 1));
          final ofDay = doses.where((x) => !x.scheduledAt.isBefore(day) && x.scheduledAt.isBefore(next)).toList();
          return [
            for (final p in DosePeriod.values)
              periodStatus(ofDay.where((x) => periodOfTime(x.scheduledAt) == p).toList(), alerted),
          ];
        }(),
    ];
    return Elder(
      id: id,
      name: name,
      nickname: (d['apelido'] as String?) ?? name.split(RegExp(r'\s+')).first,
      age: (d['idade'] as num?)?.toInt() ?? 0,
      conditions: (d['condicoes'] as String?) ?? '',
      usesApp: (d['usaApp'] as bool?) ?? true,
      phone: (d['telefone'] as String?) ?? '',
      links: {
        for (final l in links.entries)
          l.key: CareLink(
            caregiverIs: ((l.value as Map)['cuidadorE'] as String?) ?? 'Cuidador(a)',
            elderIs: ((l.value as Map)['idosoE'] as String?) ?? '',
          ),
      },
      doctorIds: List<String>.from((d['medicosIds'] as List?) ?? const []),
      history: history,
    );
  }

  Medication _medFrom(String elderId, String id, Map<String, dynamic> d) {
    final times = [
      for (final t in (d['horarios'] as List?) ?? const [])
        TimeOfDay(hour: int.parse((t as String).split(':')[0]), minute: int.parse(t.split(':')[1])),
    ];
    return Medication(
      id: id,
      elderId: elderId,
      name: (d['nome'] as String?) ?? '',
      dosage: (d['dose'] as String?) ?? '',
      times: times,
      weekdays: {for (final w in (d['diasSemana'] as List?) ?? const [1, 2, 3, 4, 5, 6, 7]) (w as num).toInt()},
      start: _date(d['inicio']) ?? DateTime.now(),
      end: _date(d['fim']),
      alertMinutes: (d['prazoAlertaMin'] as num?)?.toInt() ?? 30,
      origin: MedicationOrigin.values.byName((d['origem'] as String?) ?? 'familia'),
      createdByName: (d['criadoPorNome'] as String?) ?? '',
      history: List<String>.from((d['historico'] as List?) ?? const []),
    );
  }

  Dose _doseFrom(String elderId, String id, Map<String, dynamic> d) => Dose(
        id: id,
        elderId: elderId,
        medicationId: (d['medicamentoId'] as String?) ?? '',
        medicationName: (d['nomeRemedio'] as String?) ?? '',
        dosageText: (d['dose'] as String?) ?? '',
        scheduledAt: _date(d['agendadaPara']) ?? DateTime.now(),
        status: DoseStatus.values.asNameMap()[d['estado']] ?? DoseStatus.pendente,
        snoozeCount: (d['adiamentos'] as num?)?.toInt() ?? 0,
        reminderCount: (d['lembretes'] as num?)?.toInt() ?? 0,
        confirmedAt: _date(d['confirmadoEm']),
        confirmedBy: d['confirmadoPor'] as String?,
      );

  CareAlert _alertFrom(String elderId, String id, Map<String, dynamic> d) => CareAlert(
        id: id,
        elderId: elderId,
        doseId: (d['doseId'] as String?) ?? id,
        medicationName: (d['nomeRemedio'] as String?) ?? '',
        doseTime: _date(d['horaDose']) ?? DateTime.now(),
        reason: d['motivo'] == 'adiouDuasVezes' ? AlertReason.adiouDuasVezes : AlertReason.semResposta,
        createdAt: _date(d['criadoEm']) ?? DateTime.now(),
        resolvedAt: _date(d['resolvidoEm']),
      );

  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

  // ---------------------------------------------------------------------------
  // Escrita

  DocumentReference<Map<String, dynamic>> _elderRef(String id) => _db.collection('idosos').doc(id);

  /// Mesmo id usado pelo agendador, para a dose nunca ser criada duas vezes.
  static String doseId(String medicationId, DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${medicationId}_${at.year}${two(at.month)}${two(at.day)}${two(at.hour)}${two(at.minute)}';
  }

  /// "Tomei". A transação garante que a mesma dose não é confirmada duas
  /// vezes, mesmo com o idoso e o cuidador tocando ao mesmo tempo.
  Future<void> confirmDose(Dose d, {required bool byCaregiver}) async {
    final ref = _elderRef(d.elderId).collection('doses').doc(d.id);
    final alertRef = _elderRef(d.elderId).collection('alertas').doc(d.id);
    await _db.runTransaction((tx) async {
      final s = await tx.get(ref);
      if (!s.exists || s.data()!['estado'] == 'tomada') return;
      final a = await tx.get(alertRef);
      tx.update(ref, {
        'estado': 'tomada',
        'confirmadoEm': Timestamp.now(),
        'confirmadoPor': byCaregiver ? 'cuidador' : 'idoso',
        'confirmadoPorUid': uid,
      });
      if (a.exists && a.data()!['resolvidoEm'] == null) {
        tx.update(alertRef, {'resolvidoEm': Timestamp.now(), 'resolvidoPor': uid});
      }
    });
  }

  /// "Me lembra em 15 min". No segundo adiamento nasce o alerta, e o
  /// agendador avisa o cuidador.
  Future<void> snooze(Dose d) async {
    final ref = _elderRef(d.elderId).collection('doses').doc(d.id);
    final alertRef = _elderRef(d.elderId).collection('alertas').doc(d.id);
    await _db.runTransaction((tx) async {
      final s = await tx.get(ref);
      if (!s.exists) return;
      final data = s.data()!;
      final count = (data['adiamentos'] as num?)?.toInt() ?? 0;
      if (data['estado'] == 'tomada' || count >= 2) return;
      final a = await tx.get(alertRef);
      if (count + 1 >= 2) {
        tx.update(ref, {'adiamentos': 2, 'estado': 'atrasada', 'alertado': true});
        if (!a.exists) {
          tx.set(alertRef, {
            'doseId': d.id,
            'nomeRemedio': d.medicationName,
            'horaDose': Timestamp.fromDate(d.scheduledAt),
            'motivo': 'adiouDuasVezes',
            'criadoEm': Timestamp.now(),
            'resolvidoEm': null,
            'notificado': false,
          });
        }
      } else {
        tx.update(ref, {'adiamentos': count + 1, 'estado': 'adiada'});
      }
    });
  }

  Future<void> remindCaregiverLater(Dose d) =>
      _elderRef(d.elderId).collection('doses').doc(d.id).update({'estado': 'adiada'});

  Future<void> addMedication({
    required String elderId,
    required String name,
    required String dosage,
    required List<TimeOfDay> times,
    required Set<int> weekdays,
    required DateTime start,
    required DateTime? end,
    required int alertMinutes,
    required MedicationOrigin origin,
    required String historyLine,
  }) async {
    final ref = _elderRef(elderId).collection('medicamentos').doc();
    await ref.set({
      ..._medFields(name, dosage, times, weekdays, start, end, alertMinutes),
      'origem': origin.name,
      'criadoPorNome': me?.name ?? '',
      'criadoPorUid': uid,
      'criadoEm': Timestamp.now(),
      'encerradoEm': null,
      'historico': [historyLine],
    });
    await _scheduleToday(elderId, ref.id, name.trim(), dosage.trim(), times, weekdays, start, end);
  }

  Future<void> updateMedication(
    Medication m, {
    required String name,
    required String dosage,
    required List<TimeOfDay> times,
    required Set<int> weekdays,
    required DateTime start,
    required DateTime? end,
    required int alertMinutes,
    required String historyLine,
  }) async {
    final ref = _elderRef(m.elderId).collection('medicamentos').doc(m.id);
    await ref.update({
      ..._medFields(name, dosage, times, weekdays, start, end, alertMinutes),
      'atualizadoEm': Timestamp.now(),
      'historico': FieldValue.arrayUnion([historyLine]),
    });
    // Refaz só as doses que ainda vão tocar.
    final now = DateTime.now();
    final batch = _db.batch();
    for (final d in _doses[m.elderId] ?? const <Dose>[]) {
      if (d.medicationId == m.id && d.isOpen && d.scheduledAt.isAfter(now)) {
        batch.delete(_elderRef(m.elderId).collection('doses').doc(d.id));
      }
    }
    await batch.commit();
    await _scheduleToday(m.elderId, m.id, name.trim(), dosage.trim(), times, weekdays, start, end);
  }

  Map<String, dynamic> _medFields(String name, String dosage, List<TimeOfDay> times, Set<int> weekdays,
      DateTime start, DateTime? end, int alertMinutes) {
    String two(int n) => n.toString().padLeft(2, '0');
    final sorted = List.of(times)..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    return {
      'nome': name.trim(),
      'dose': dosage.trim(),
      'horarios': [for (final t in sorted) '${two(t.hour)}:${two(t.minute)}'],
      'diasSemana': (weekdays.toList()..sort()),
      'inicio': Timestamp.fromDate(DateTime(start.year, start.month, start.day)),
      'fim': end == null ? null : Timestamp.fromDate(DateTime(end.year, end.month, end.day)),
      'prazoAlertaMin': alertMinutes,
    };
  }

  /// Cria agora as doses que ainda vão tocar hoje. As dos próximos dias o
  /// agendador cria.
  Future<void> _scheduleToday(String elderId, String medId, String name, String dosage, List<TimeOfDay> times,
      Set<int> weekdays, DateTime start, DateTime? end) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!weekdays.contains(today.weekday) || today.isBefore(DateTime(start.year, start.month, start.day))) return;
    if (end != null && today.isAfter(DateTime(end.year, end.month, end.day))) return;
    final batch = _db.batch();
    for (final t in times) {
      final at = DateTime(today.year, today.month, today.day, t.hour, t.minute);
      if (!at.isAfter(now)) continue; // lembretes começam do próximo horário
      batch.set(_elderRef(elderId).collection('doses').doc(doseId(medId, at)), {
        'medicamentoId': medId,
        'idosoId': elderId,
        'nomeRemedio': name,
        'dose': dosage,
        'agendadaPara': Timestamp.fromDate(at),
        'estado': 'pendente',
        'adiamentos': 0,
        'lembretes': 0,
        'alertado': false,
        'criadoEm': Timestamp.now(),
      });
    }
    await batch.commit();
  }

  Future<void> createInvite(Invite invite) => _db.collection('convites').doc(invite.code).set({
        'cuidadorUid': uid,
        'cuidadorNome': me?.name ?? '',
        'cuidadorE': invite.caregiverIs,
        'idosoE': invite.elderIs,
        'expiraEm': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
        'criadoEm': Timestamp.now(),
      });

  Future<Invite?> findInvite(String code) async {
    final s = await _db.collection('convites').doc(code).get();
    final d = s.data();
    if (d == null) return null;
    final expires = _date(d['expiraEm']);
    if (expires != null && expires.isBefore(DateTime.now())) return null;
    return Invite(
      code: code,
      caregiverId: d['cuidadorUid'] as String,
      caregiverIs: (d['cuidadorE'] as String?) ?? 'Cuidador(a)',
      elderIs: (d['idosoE'] as String?) ?? '',
      caregiverName: d['cuidadorNome'] as String?,
    );
  }

  Future<void> acceptInvite(Invite invite, Elder elder) async {
    final batch = _db.batch();
    batch.update(_elderRef(elder.id), {
      'cuidadoresIds': FieldValue.arrayUnion([invite.caregiverId]),
      'vinculos.${invite.caregiverId}': {
        'nome': invite.caregiverName ?? 'Cuidador(a)',
        'cuidadorE': invite.caregiverIs,
        'idosoE': invite.elderIs,
      },
    });
    batch.delete(_db.collection('convites').doc(invite.code));
    await batch.commit();
  }

  Future<void> declineInvite(Invite invite) => _db.collection('convites').doc(invite.code).delete();

  Future<void> removeCaregiver(Elder elder, String caregiverId) => _elderRef(elder.id).update({
        'cuidadoresIds': FieldValue.arrayRemove([caregiverId]),
        'vinculos.$caregiverId': FieldValue.delete(),
      });

  /// Cadastro de idoso sem app, feito pelo cuidador.
  Elder addElderWithoutApp({
    required String name,
    required int age,
    required String elderIs,
    required String phone,
  }) {
    final ref = _db.collection('idosos').doc();
    final cleanName = name.trim();
    final first = cleanName.split(RegExp(r'\s+')).first;
    final link = CareLink(caregiverIs: 'Cuidador(a)', elderIs: elderIs);
    ref.set({
      'usuarioId': null,
      'nome': cleanName,
      'apelido': first,
      'idade': age,
      'condicoes': '',
      'telefone': phone.trim(),
      'usaApp': false,
      'cuidadoresIds': [uid],
      'vinculos': {
        uid!: {'nome': me?.name ?? '', 'cuidadorE': link.caregiverIs, 'idosoE': link.elderIs},
      },
      'medicosIds': <String>[],
      'medicos': <String, dynamic>{},
      'fusoHorario': 'America/Sao_Paulo',
      'criadoPor': uid,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    return Elder(
      id: ref.id,
      name: cleanName,
      nickname: first,
      age: age,
      conditions: '',
      usesApp: false,
      phone: phone.trim(),
      links: {uid!: link},
      doctorIds: [],
      history: List.generate(13, (_) => List.filled(3, DoseStatus.pendente)),
    );
  }

  /// O médico pede para acompanhar o paciente. O vínculo só nasce quando o
  /// paciente aceita, na aba Família do app dele.
  Future<String?> requestPatient(String email) async {
    final mail = email.trim().toLowerCase();
    final s = await _db.collection('emails').doc(mail).get();
    final elderId = s.data()?['idosoId'] as String?;
    if (elderId == null) {
      return 'Não encontramos um paciente com esse email. Ele precisa ter uma conta de idoso no app CuidarMais.';
    }
    if (_elderDocs.containsKey(elderId)) return 'Esse paciente já está na sua lista.';
    await _elderRef(elderId).collection('pedidosMedico').doc(uid).set({
      'medicoUid': uid,
      'nome': me?.name ?? 'Médico(a)',
      'detalhe': me?.detail,
      'criadoEm': Timestamp.now(),
    });
    return null;
  }

  Future<void> answerDoctorRequest(String elderId, DoctorRequest r, {required bool accept}) async {
    final batch = _db.batch();
    if (accept) {
      batch.update(_elderRef(elderId), {
        'medicosIds': FieldValue.arrayUnion([r.doctorId]),
        'medicos.${r.doctorId}': {'nome': r.name, 'detalhe': r.detail},
      });
    }
    batch.delete(_elderRef(elderId).collection('pedidosMedico').doc(r.doctorId));
    await batch.commit();
  }
}
