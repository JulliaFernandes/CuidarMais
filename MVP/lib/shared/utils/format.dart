import 'package:flutter/material.dart' show TimeOfDay;

/// Formatação de datas e horários em português, sem depender de pacotes.

String two(int n) => n.toString().padLeft(2, '0');

String hhmm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

String hhmmOf(TimeOfDay t) => '${two(t.hour)}:${two(t.minute)}';

int compareTimeOfDay(TimeOfDay a, TimeOfDay b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute);

const _weekdayNames = [
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

/// Índice = DateTime.weekday - 1.
const weekdayShort = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

const _months = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// "Segunda-feira, 19 de outubro"
String longDate(DateTime d) {
  final w = _weekdayNames[d.weekday - 1];
  return '${w[0].toUpperCase()}${w.substring(1)}, ${d.day} de ${_months[d.month - 1]}';
}

/// "19/10/2026"
String shortDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String daysLabel(Set<int> days) {
  if (days.length == 7) return 'todos os dias';
  final sorted = days.toList()..sort();
  return sorted.map((d) => weekdayShort[d - 1]).join(', ');
}

String timesLabel(List<TimeOfDay> times) {
  final sorted = List.of(times)..sort(compareTimeOfDay);
  return sorted.map(hhmmOf).join(' · ');
}

String plural(int n, String one, String many) => n == 1 ? one : many;
