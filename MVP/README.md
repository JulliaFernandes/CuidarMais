# Cuidar+ — frontend (Flutter)

Protótipo de frontend em **Flutter**, só pra validar a stack definida no documento do
projeto. Sem backend: os dados são mockados em `lib/data/mock/mock_data.dart`.

## Duas abas

O app abre com um seletor fixo no topo com duas visões:

- **Idoso** (verde) — protótipo do futuro app: lembrete atual (com "Tomei" / "Me
  lembra em 15 min", até 2 adiamentos), a lista do dia em letras grandes e uma
  **simulação fiel do WhatsApp** (é por lá que o lembrete chega hoje — ver README do
  repositório).
- **Médico** (violeta) — painel com os resultados: lista de pacientes por exceção
  (vermelho/amarelo/verde), **régua do dia** (horários de todos os pacientes numa
  linha do tempo), relatório individual com **anel de adesão** (donut, com a
  proporção real de tomada/atraso/perda dos últimos 14 dias) e **heatmap de 14 dias
  por período** (identifica padrão de esquecimento, ex. "sempre esquece a tarde") e
  cadastro de medicamento.

Cada aba tem sua cor de destaque (verde para o idoso, violeta para o médico) — ajuda
a identificar de relance em qual visão você está. Trocar de aba é sempre uma ação
explícita (toque nos botões "Idoso"/"Médico"), nunca automático. Números e títulos
grandes usam uma fonte de destaque (Bricolage Grotesque via `google_fonts`) pra
contrastar com o corpo do texto.

## Como rodar

Este diretório ainda não tem os projetos de plataforma (`android/`, `ios/`, `web/`
etc.) gerados. Para rodar:

```bash
cd src
flutter create --platforms=android,ios,web .   # gera as pastas de plataforma, sem mexer em lib/ e pubspec.yaml
flutter pub get
flutter run -d chrome                          # ou -d <dispositivo/emulador>
```

Se o `flutter create` perguntar se quer sobrescrever `pubspec.yaml` ou arquivos em
`lib/`, **responda não** — eles já estão prontos aqui.

## Estrutura de pastas

```
lib/
├── main.dart                     # ponto de entrada
├── app.dart                      # MaterialApp, tema, controle de zoom de texto
├── core/
│   ├── accessibility/
│   │   └── text_scale_controller.dart   # controle de tamanho de texto (até 200%)
│   └── theme/
│       ├── app_colors.dart       # paleta com contraste verificado
│       └── app_theme.dart        # ThemeData: fontes grandes, alvos de toque grandes
├── data/
│   ├── models/                   # Dose, PatientSummary (sem Flutter/UI aqui)
│   └── mock/
│       └── mock_data.dart        # dados fictícios (Dona Maria, Dra. Helena, Carla)
├── shared/
│   └── widgets/                  # usados nas duas abas: RoleShell, StatusChip, etc.
└── features/
    ├── idoso/
    │   ├── idoso_theme_scope.dart  # aplica o verde só dentro desta aba
    │   ├── screens/                # Lembretes, Meus remédios, simulação de WhatsApp
    │   └── widgets/                 # DoseReminderCard
    └── medico/
        ├── screens/                # Visão geral, Relatório do paciente, Cadastro
        └── widgets/                 # PatientTile, AttentionList, AdherenceRing
                                      # (donut, fl_chart), AdherenceHeatmap, DayTimeline
```

Pacotes extras usados: `fl_chart` (anel de adesão) e `google_fonts` (fonte de
destaque Bricolage Grotesque nos títulos/números).

## Acessibilidade aplicada (WAI — Developing for Older Users)

Seguindo as recomendações do W3C para usuários mais velhos
(<https://www.w3.org/WAI/older-users/developing/>), mapeadas pelos critérios WCAG:

| Área | O que foi aplicado | Onde |
|---|---|---|
| Visão (1.4.4, G178) | Controle de texto na própria tela (A-/A+), até 200%, sempre visível | `FontSizeToggle`, `app.dart` |
| Visão (1.4.3/1.4.6) | Contraste mínimo 4,5:1, fundo levemente fora do branco puro | `app_colors.dart` |
| Visão (1.4.1, G14) | Status nunca só por cor: sempre ícone + texto junto | `StatusChip`, `PatientTile`, `AttentionList` |
| Visão (1.4.8) | Texto nunca justificado, altura de linha generosa, fonte grande por padrão | `app_theme.dart` |
| Destreza/motor | Botões com altura mínima 56–64px, ícones com alvo mínimo de 48×48 | `app_theme.dart`, `font_size_toggle.dart` |
| Destreza/motor | Alternância de aba por toque (não por gesto de arrastar) | `role_shell.dart` |
| Cognitivo (2.2.1) | Nenhum cronômetro que trava a tela sozinho: "Me lembra em 15 min" continua disponível até o 2º adiamento | `dose_reminder_card.dart` |
| Cognitivo (3.2.1/3.2.5) | Troca de contexto só por ação explícita do usuário, nunca automática | `role_shell.dart` |
| Cognitivo (2.4.6/2.4.10) | Hierarquia de headings marcada (`Semantics(header: true)`) em toda seção | `section_heading.dart` |
| Cognitivo (3.2.3/3.2.4) | Mesma estrutura de navegação (barra inferior com 2 destinos) nas duas abas | `idoso_home_screen.dart`, `medico_overview_screen.dart` |
| Cognitivo (3.3.1–3.3.4) | Formulário com instrução no início, erro descrito em texto, e etapa de revisão antes de salvar | `medico_new_medication_screen.dart` |
| Cognitivo (linguagem simples) | Frases curtas, sem jargão técnico nos textos voltados ao idoso | telas de `features/idoso/` |
| Leitor de tela (1.1.1/1.3.1) | `Semantics` com rótulos descritivos em cartões, chips e botões | em todos os widgets interativos |
| Visão (1.4.1) | Anel e heatmap de adesão também viram texto (percentual, rótulo de status, insight do padrão) — nunca só a cor da fatia ou do quadrado | `adherence_ring.dart`, `adherence_heatmap.dart` |

## O que ainda falta (de propósito)

- **Sem backend**: não há Supabase/API real — tudo é mock em memória.
- **Sem persistência entre telas fora do que foi explicitamente compartilhado**: a
  lista de doses da aba Idoso é compartilhada entre as duas telas da aba (Lembretes e
  Meus remédios), mas não é sincronizada com a aba Médico — isso só faz sentido depois
  que existir um backend de verdade.
- **Sem cuidador**: por pedido, este protótipo só cobre as visões de idoso e médico.
  O cuidador pode entrar depois como uma terceira aba ou dentro do painel do médico.
- **A simulação do WhatsApp é independente**: tem seu próprio estado de conversa, não
  compartilha dados com a tela "Lembretes" — é só uma demonstração visual do canal.
- **`google_fonts` baixa a fonte em tempo de execução** (e guarda em cache). Se rodar
  sem internet na primeira vez, cai pro fallback do sistema sem quebrar, só sem o
  mesmo destaque visual.
- **Sem testes automatizados além do smoke test** — é só para validar a interface e a stack.
