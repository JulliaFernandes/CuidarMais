import 'package:flutter/widgets.dart';
import '../../core/accessibility/text_scale_controller.dart';
import 'app_store.dart';

/// Disponibiliza o [AppStore] para qualquer tela, inclusive as abertas por
/// cima (rotas), e reconstrói quem depende dele quando algo muda.
class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  /// Use no `build`: a tela é reconstruída quando o estado muda.
  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Use em ações (botões): lê o estado sem criar dependência.
  static AppStore read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget as AppScope).notifier!;
}

/// Mesmo esquema para o controle de tamanho do texto, que aparece no
/// topo de todas as telas.
class TextScaleScope extends InheritedNotifier<TextScaleController> {
  const TextScaleScope({super.key, required TextScaleController controller, required super.child})
      : super(notifier: controller);

  static TextScaleController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TextScaleScope>()!.notifier!;
}
