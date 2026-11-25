import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'alarm_plan.dart';

/// Alarme no navegador enquanto o site está aberto (mesmo em outra aba ou
/// minimizado): na hora do remédio mostra a notificação e toca um bipe que
/// repete até a pessoa tocar na tela. Com o site fechado, quem avisa é a
/// notificação push do agendador.
class WebAlarms {
  WebAlarms._();

  static void Function(String title, String body)? onRing;

  static List<AlarmPlan> _plans = const [];
  static final Set<int> _fired = {};
  static Timer? _tick;
  static Timer? _ring;
  static Timer? _ringLimit;
  static web.AudioContext? _audio;

  static void init() {
    // O navegador só libera o som depois de um toque na página. Tocar na
    // tela também cala o alarme, como num despertador.
    void onTouch(web.Event _) {
      try {
        _audio ??= web.AudioContext();
        if (_audio!.state == 'suspended') _audio!.resume();
      } catch (_) {}
      if (_ring != null) stop();
    }

    final listener = onTouch.toJS;
    web.document.addEventListener('pointerdown', listener, true.toJS);
    web.document.addEventListener('keydown', listener, true.toJS);
  }

  static void sync(List<AlarmPlan> plans) {
    _check(); // não perde um alarme que venceu entre duas atualizações
    _plans = List.of(plans);
    _tick ??= Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  static void clear() {
    stop();
    _plans = const [];
    _fired.clear();
    _tick?.cancel();
    _tick = null;
  }

  static void _check() {
    final now = DateTime.now();
    for (final p in _plans) {
      if (p.at.isAfter(now) || !_fired.add(p.id)) continue;
      // Se o computador estava dormindo, não toca lembrete muito antigo.
      if (now.difference(p.at) < const Duration(minutes: 10)) _fire(p);
    }
  }

  static void _fire(AlarmPlan p) {
    _showNotification(p);
    onRing?.call(p.title, p.body);
    stop();
    _beep();
    _ring = Timer.periodic(const Duration(seconds: 2), (_) => _beep());
    _ringLimit = Timer(const Duration(minutes: 3), stop);
  }

  static void stop() {
    _ring?.cancel();
    _ring = null;
    _ringLimit?.cancel();
    _ringLimit = null;
  }

  static Future<void> _showNotification(AlarmPlan p) async {
    try {
      if (web.Notification.permission != 'granted') return;
      final options = web.NotificationOptions(
        body: p.body,
        tag: 'cuidarmais-${p.id}',
        requireInteraction: true,
        icon: 'icons/Icon-192.png',
      );
      // No celular, só o service worker pode mostrar notificação.
      final regs = (await web.window.navigator.serviceWorker.getRegistrations().toDart).toDart;
      if (regs.isNotEmpty) {
        await regs.first.showNotification(p.title, options).toDart;
      } else {
        web.Notification(p.title, options);
      }
    } catch (_) {}
  }

  /// Três bipes curtos e agudos, sem arquivo de som.
  static void _beep() {
    final ctx = _audio;
    if (ctx == null) return;
    try {
      if (ctx.state == 'suspended') ctx.resume();
      final t = ctx.currentTime;
      for (var i = 0; i < 3; i++) {
        final start = t + i * 0.3;
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.type = 'square';
        osc.frequency.value = 880;
        gain.gain.setValueAtTime(0, start);
        gain.gain.linearRampToValueAtTime(0.25, start + 0.02);
        gain.gain.setValueAtTime(0.25, start + 0.18);
        gain.gain.linearRampToValueAtTime(0, start + 0.2);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(start);
        osc.stop(start + 0.22);
      }
    } catch (_) {}
  }
}
