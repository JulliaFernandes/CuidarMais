/// Um alarme a agendar no aparelho.
class AlarmPlan {
  final int id;
  final DateTime at;
  final String title;
  final String body;

  const AlarmPlan({required this.id, required this.at, required this.title, required this.body});
}
