import 'package:flutter/foundation.dart';

/// Controla o tamanho do texto do app inteiro.
///
/// Atende WCAG 1.4.4 (Redimensionar texto até 200%, nível AA) com um
/// controle sempre visível na própria tela (técnica G178), em vez de
/// depender só do zoom do sistema operacional — muitos idosos não sabem
/// onde fica essa opção no aparelho.
class TextScaleController extends ChangeNotifier {
  static const double _min = 1.0;
  static const double _max = 2.0;
  static const double _step = 0.25;

  double _scale = 1.0;
  double get scale => _scale;

  bool get canIncrease => _scale < _max;
  bool get canDecrease => _scale > _min;

  void increase() {
    if (!canIncrease) return;
    _scale = (_scale + _step).clamp(_min, _max);
    notifyListeners();
  }

  void decrease() {
    if (!canDecrease) return;
    _scale = (_scale - _step).clamp(_min, _max);
    notifyListeners();
  }
}
