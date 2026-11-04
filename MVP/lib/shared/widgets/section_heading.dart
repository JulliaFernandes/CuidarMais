import 'package:flutter/material.dart';

/// Título de seção com hierarquia de heading marcada para leitor de tela
/// (WCAG 2.4.6 / 2.4.10) — permite pular de seção em seção sem ler tudo.
class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SectionHeading({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
