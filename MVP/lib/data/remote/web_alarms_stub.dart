import 'alarm_plan.dart';

/// Fora do navegador não há alarme de página aberta (o Android usa os
/// alarmes do sistema).
class WebAlarms {
  WebAlarms._();

  static void Function(String title, String body)? onRing;
  static void init() {}
  static void sync(List<AlarmPlan> plans) {}
  static void clear() {}
}
