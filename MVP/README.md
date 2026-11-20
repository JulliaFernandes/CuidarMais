# CuidarMais — MVP (app em Flutter)

O app do CuidarMais em **Flutter**. Todas as telas e regras já funcionam, com dados de demonstração.
Para o MVP ficar completo, falta trocar esses dados pela API, com banco, login real e notificações
(veja [`../docs/ETAPAS.md`](../docs/ETAPAS.md)).

Segue o documento do projeto v2: app para
**idoso** e **cuidador**, e o painel do **médico** (que no produto final será web, em Next.js, mas
aqui roda no mesmo app para validar as telas).

Ainda **sem backend**: os dados ficam em memória (`lib/data/store/app_store.dart`) e começam a
partir de `lib/data/mock/mock_data.dart`. Como tudo é compartilhado, o que acontece em um perfil
aparece nos outros: se a Dona Maria adia o lembrete 2 vezes, a Carla recebe o alerta e o caso fica
vermelho no painel da Dra. Helena.

## Como rodar

```bash
cd MVP
flutter pub get
flutter run -d chrome        # ou -d edge, ou um celular Android ligado no cabo
```

Testes:

```bash
flutter test
```

## Contas de demonstração

Na tela de login há atalhos para entrar direto. Todas as contas usam a senha `123456`.

| Conta | Perfil | O que mostra |
|---|---|---|
| `maria@cuidar.app` | Idosa, usa o app | Chat de lembretes com a Losartana das 08:00 esperando |
| `carla@cuidar.app` | Cuidadora | Acompanha a Dona Maria (com app) e o Seu Antônio (sem app) |
| `helena@cuidar.app` | Médica | Painel por exceção com 4 pacientes |

**Controles da demonstração** (menu da conta, no canto superior direito):
- **Passar 15 minutos:** avança o relógio, que começa às 08:05. Serve para ver o alerta "sem
  resposta" (30 minutos) e os avisos a cada 15 minutos do idoso sem app.
- **Recomeçar demonstração:** volta tudo ao início.

**Roteiro sugerido:** entre como Dona Maria e toque 2 vezes em "Me lembra em 15 min". Saia, entre
como Carla e veja o alerta. Saia, entre como Dra. Helena e veja a Dona Maria em "Precisam de atenção".

## Telas

**Entrada**
- Boas-vindas, login, cadastro em 3 passos (perfil → dados → consentimento LGPD) e recuperar senha.

**Idoso** (verde)
- **Lembretes:** chat com uma mensagem por horário e o lembrete atual com **Tomei** e **Me lembra
  em 15 min** (até 2 vezes; no segundo adiamento o cuidador é avisado).
- **Hoje:** remédios do dia em letras grandes.
- **Remédios:** todos os remédios, com quem cadastrou cada um; o idoso também pode cadastrar e editar.
- **Família:** digitar o código de convite de um cuidador, aceitar ou recusar, tirar acesso.

**Cuidador** (laranja)
- **Início:** alertas abertos com o nome do remédio e cada pessoa acompanhada com o status do dia.
- **Alertas:** histórico de alertas abertos e resolvidos.
- **Ficha do idoso com app:** doses de hoje, últimos 7 dias, remédios (cadastrar e editar).
- **Ficha do idoso sem app:** a mesma tela de lembretes do idoso, para o cuidador confirmar por ele,
  com aviso a cada 15 minutos até confirmar.
- **Adicionar idoso:** "a pessoa vai usar o app?" Sim → gera um código; não → cadastro direto.

**Médico** (violeta)
- **Pacientes:** "Precisam de atenção", régua do dia e todos os pacientes, sem notificações.
- **Relatório:** anel de adesão, mapa de 14 dias por período, doses de hoje (com quem confirmou) e
  remédios com a origem (prescrição validada, família ou paciente).
- **Cadastrar:** escolhe o paciente e abre o formulário de remédio.
- **Adicionar paciente:** pelo email da conta do paciente (proposta; a forma final está em aberto).

O formulário de remédio é o mesmo para os três perfis (`lib/shared/screens/medication_form_screen.dart`),
com etapa de revisão antes de salvar. Muda só a origem registrada.

## Estrutura de pastas

```
lib/
├── main.dart
├── app.dart                         # MaterialApp, tema por perfil, português, tamanho do texto
├── core/
│   ├── accessibility/text_scale_controller.dart
│   └── theme/                       # cores com contraste verificado, ThemeData por perfil
├── data/
│   ├── models/                      # Dose, Medication, Elder, AppUser, CareAlert, PatientSummary
│   ├── mock/mock_data.dart          # personagens e dados iniciais
│   └── store/                       # AppStore (faz o papel do backend) e AppScope
├── shared/
│   ├── screens/medication_form_screen.dart
│   ├── utils/format.dart            # datas e horários em português
│   └── widgets/                     # barra do topo, chat de lembretes, avisos, selos, semana etc.
└── features/
    ├── auth/                        # boas-vindas, login, cadastro, recuperar senha
    ├── idoso/                       # Lembretes, Hoje, Remédios, Família
    ├── cuidador/                    # Início, Alertas, ficha do idoso, adicionar idoso
    └── medico/                      # Pacientes, relatório, cadastrar, adicionar paciente
```

Pacotes usados: `fl_chart` (anel de adesão), `google_fonts` (fonte de destaque Bricolage Grotesque)
e `flutter_localizations` (calendário e relógio em português).

## Acessibilidade aplicada (WAI — Developing for Older Users)

Seguindo as recomendações do W3C para usuários mais velhos
(<https://www.w3.org/WAI/older-users/developing/>), mapeadas pelos critérios WCAG:

| Área | O que foi aplicado | Onde |
|---|---|---|
| Visão (1.4.4, G178) | Controle de texto na própria tela (A-/A+), até 200%, visível em todas as telas, inclusive antes do login | `FontSizeToggle`, `AppTopBar` |
| Visão (1.4.10) | Nada estoura a tela com o texto em 200%: linhas quebram em vez de cortar (testado em 360×740) | `test/widget_test.dart` |
| Visão (1.4.3/1.4.6) | Contraste mínimo 4,5:1, fundo levemente fora do branco puro | `app_colors.dart` |
| Visão (1.4.1, G14) | Status nunca só por cor: sempre ícone + texto junto (inclusive a semana em círculos e a origem do remédio) | `StatusChip`, `NoticeBox`, `WeekStrip`, `OriginChip` |
| Visão (1.4.8) | Texto nunca justificado, altura de linha generosa, fonte grande por padrão | `app_theme.dart` |
| Destreza/motor | Botões com altura mínima 56–64px, ícones com alvo mínimo de 48×48 | `app_theme.dart` |
| Destreza/motor | Troca de aba e de visão por toque (barra inferior e botões segmentados), nunca por gesto de arrastar | telas `*_home_screen.dart`, `cuidador_elder_screen.dart` |
| Destreza/motor | Horário digitado em vez de arrastar o ponteiro do relógio | `medication_form_screen.dart` |
| Cognitivo (2.2.1) | Nenhum cronômetro que trava a tela: "Me lembra em 15 min" continua disponível até o 2º adiamento | `dose_reminder_card.dart` |
| Cognitivo (3.2.1/3.2.5) | Troca de contexto só por ação explícita (entrar, sair, tocar), nunca automática | `auth_gate.dart` |
| Cognitivo (3.2.3/3.2.4) | Mesma estrutura de navegação (barra inferior) nos três perfis | telas `*_home_screen.dart` |
| Cognitivo (2.4.6/2.4.10) | Hierarquia de headings marcada (`Semantics(header: true)`) em toda seção | `section_heading.dart` |
| Cognitivo (3.3.1–3.3.4) | Formulários com instrução no início, erro descrito em texto, etapa de revisão antes de salvar | `medication_form_screen.dart`, `signup_screen.dart` |
| Cognitivo | Cadastro dividido em 3 passos curtos, com "Passo X de 3" em texto | `signup_screen.dart` |
| Cognitivo (linguagem simples) | Frases curtas, sem jargão técnico nos textos voltados ao idoso | telas de `features/idoso/` |
| Leitor de tela (1.1.1/1.3.1/4.1.3) | `Semantics` com rótulos descritivos; alertas e erros anunciados assim que aparecem (`liveRegion`) | `AlertBanner`, `NoticeBox`, `DoseReminderCard` |

## O que ainda falta (de propósito)

- **Sem backend:** tudo fica em memória e volta ao início ao recarregar a página.
- **Sem notificações de verdade:** o lembrete aparece no chat; push (Firebase Cloud Messaging) e
  agendamento local no aparelho entram com o backend.
- **Relógio simulado:** começa às 08:05 e anda só pelo menu da demonstração.
- **Painel do médico dentro do app:** no produto final ele é web (Next.js).
- **Fila de revisão, foto da receita, alergias e estoque:** ficam para depois do MVP, como no documento.
- **`google_fonts` baixa a fonte em tempo de execução** (e guarda em cache). Sem internet na primeira
  vez, cai para a fonte do sistema sem quebrar.
