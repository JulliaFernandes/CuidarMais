import 'package:flutter/material.dart';

/// Símbolo do CuidarMais (a cruz com o coração). É decorativo: o nome do
/// app sempre aparece em texto ao lado, então o leitor de tela pula a imagem.
///
/// A logo completa e os originais ficam em `identidade-visual/`, na raiz do
/// repositório.
class CuidarLogo extends StatelessWidget {
  final double size;
  const CuidarLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Image.asset(
        'assets/marca/simbolo.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
