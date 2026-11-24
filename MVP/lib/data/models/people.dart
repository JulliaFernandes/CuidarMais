import 'dose.dart';

enum UserRole { idoso, cuidador, medico }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.idoso:
        return 'Idoso';
      case UserRole.cuidador:
        return 'Cuidador';
      case UserRole.medico:
        return 'Médico';
    }
  }
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;

  /// Só para quem tem perfil de idoso: aponta para os dados de saúde dele.
  final String? elderId;

  /// Linha extra do perfil (ex.: "Geriatria · CRM 123456").
  final String? detail;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.elderId,
    this.detail,
  });

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
  String get initials => initialsOf(name);
}

/// Vínculo entre um cuidador e um idoso, com o parentesco visto dos dois
/// lados: [caregiverIs] aparece para o idoso ("Filha") e [elderIs] para o
/// cuidador ("Mãe").
class CareLink {
  final String caregiverIs;
  final String elderIs;
  const CareLink({required this.caregiverIs, required this.elderIs});
}

class Elder {
  final String id;
  String name;

  /// Como a família chama a pessoa no dia a dia (ex.: "Dona Maria").
  String nickname;
  int age;
  String conditions;

  /// Marcado no cadastro: o idoso usa o app no celular dele?
  bool usesApp;
  String phone;

  /// Cuidadores vinculados (id do usuário → parentesco).
  final Map<String, CareLink> links;
  final List<String> doctorIds;

  /// Últimos 13 dias antes de hoje, cada um com manhã/tarde/noite.
  final List<List<DoseStatus>> history;

  Elder({
    required this.id,
    required this.name,
    required this.nickname,
    required this.age,
    required this.conditions,
    required this.usesApp,
    required this.links,
    required this.doctorIds,
    required this.history,
    this.phone = '',
  });

  List<String> get caregiverIds => links.keys.toList();
  String get initials => initialsOf(name);
}

/// Convite gerado pelo cuidador. O idoso digita o código e aceita.
class Invite {
  final String code;
  final String caregiverId;
  final String caregiverIs;
  final String elderIs;

  /// Nome de quem convidou. Com o Firebase, o idoso ainda não tem acesso à
  /// conta do cuidador, então o nome vem junto com o convite.
  final String? caregiverName;

  const Invite({
    required this.code,
    required this.caregiverId,
    required this.caregiverIs,
    required this.elderIs,
    this.caregiverName,
  });

  String get formattedCode => '${code.substring(0, 3)}-${code.substring(3)}';
}

/// Pedido de um médico para acompanhar o idoso. Só vira vínculo quando o
/// idoso aceita (consentimento, LGPD).
class DoctorRequest {
  final String doctorId;
  final String name;
  final String? detail;

  const DoctorRequest({required this.doctorId, required this.name, this.detail});

  String get initials => initialsOf(name);
}
