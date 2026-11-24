import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Um alarme a agendar no aparelho.
class AlarmPlan {
  final int id;
  final DateTime at;
  final String title;
  final String body;

  const AlarmPlan({required this.id, required this.at, required this.title, required this.body});
}

/// Alarmes de lembrete no próprio aparelho (só no app Android).
///
/// Tocam na hora exata, sem internet e sem depender do agendador do GitHub,
/// e repetem o som até a pessoa mexer no aparelho (como um despertador).
/// Os alertas para o cuidador continuam vindo pelo agendador, porque são
/// um aparelho avisando outro.
class LocalAlarms {
  LocalAlarms._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static String _lastPlan = '';

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> init() async {
    if (!supported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Alarmes locais indisponíveis: $e');
    }
  }

  /// Mesmo canal criado em MainActivity.kt: prioridade alta e som de alarme.
  static final _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'lembretes',
      'Lembretes de remédio',
      channelDescription: 'Hora do remédio e alertas quando uma dose fica sem confirmação',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
      ticker: 'Hora do remédio',
      autoCancel: true,
      // FLAG_INSISTENT: o som repete até a pessoa abrir ou dispensar a notificação.
      additionalFlags: Int32List.fromList(<int>[4]),
    ),
  );

  /// Troca todos os alarmes agendados por [plans]. Não faz nada se a agenda
  /// não mudou.
  static Future<void> sync(List<AlarmPlan> plans) async {
    if (!_ready) return;
    final key = plans.map((p) => '${p.id}@${p.at.millisecondsSinceEpoch}').join(',');
    if (key == _lastPlan) return;
    _lastPlan = key;
    try {
      await _plugin.cancelAllPendingNotifications();
      // O Android limita a quantidade de alarmes por app; 2 dias bastam.
      for (final p in plans.take(60)) {
        final when = tz.TZDateTime.from(p.at, tz.local);
        try {
          await _plugin.zonedSchedule(
            id: p.id,
            scheduledDate: when,
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            title: p.title,
            body: p.body,
          );
        } catch (_) {
          // Sem permissão de alarme exato: agenda do jeito aproximado.
          await _plugin.zonedSchedule(
            id: p.id,
            scheduledDate: when,
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: p.title,
            body: p.body,
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao agendar alarmes: $e');
    }
  }

  static Future<void> clear() async {
    _lastPlan = '';
    if (_ready) await _plugin.cancelAllPendingNotifications();
  }
}
