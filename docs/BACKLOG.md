# Backlog do CuidarMais

Cada tarefa abaixo vira **uma issue** no GitHub. Para cada uma:

1. Copie o **Título** para o título da issue.
2. Copie o bloco **Descrição** para o corpo da issue.
3. Marque as **Labels** e o **Milestone** indicados.
4. Adicione a issue ao board na coluna **Backlog**.

O backlog segue o documento do projeto v2: app Flutter para idoso e cuidador, painel web para o médico, backend em Python com PostgreSQL e notificações pelo Firebase Cloud Messaging.

---

## Labels para criar no GitHub

Crie em **Issues → Labels → New label**. As cores são sugestões.

**Épico**

| Label | Cor | Descrição |
|---|---|---|
| `E0 · Setup` | `#6B6485` | Estrutura do projeto e ferramentas |
| `E1 · Contas e vínculos` | `#6A4DF4` | Login, perfis, convite por código e consentimento |
| `E2 · Medicamentos` | `#8E6CFF` | Cadastro com origem e geração das doses |
| `E3 · Lembretes` | `#17914F` | Chat do idoso, Tomei e Me lembra em 15 min |
| `E4 · Escalada` | `#D7263F` | Agendador, regras de alerta e push |
| `E5 · App do cuidador` | `#E4532B` | Telas do cuidador no app |
| `E6 · Painel do médico` | `#4A35C8` | Telas web do médico |
| `E7 · Depois do MVP` | `#F5B729` | Funcionalidades para depois da jornada |
| `E8 · Entregáveis` | `#221B3A` | Pesquisa, canvas, testes e pitch |

**Área**

| Label | Cor | Descrição |
|---|---|---|
| `app` | `#A8E6C1` | Flutter (idoso e cuidador) |
| `web` | `#C9BDFF` | Next.js (médico) |
| `api` | `#FFC2AE` | Backend Python |
| `banco` | `#FFE08A` | PostgreSQL: tabelas e dados |
| `push` | `#D6DFEA` | Notificações locais e Firebase Cloud Messaging |
| `docs` | `#E6E1F2` | Documentação e entregáveis |

**Prioridade**

| Label | Cor | Descrição |
|---|---|---|
| `mvp` | `#0F6B45` | Necessário para o fluxo completo da demo |
| `depois` | `#B97A00` | Fora do MVP |

**Milestones** (crie em **Issues → Milestones**): `Semana 1` a `Semana 6`.

---

## Divisão entre as duas pessoas

O documento recomenda dividir as frentes desde a semana 1, porque na semana 4 app e painel web andam juntos.

| Frente | Cuida de | Labels principais |
|---|---|---|
| **Frente App** | Flutter, notificações locais, telas do idoso e do cuidador | `app` `push` |
| **Frente API + Web** | Python, PostgreSQL, agendador, regras de escalada, painel do médico | `api` `banco` `web` |

As tarefas marcadas com as duas frentes (por exemplo, `api` + `app`) são feitas em dupla ou divididas em duas issues. Os entregáveis (`E8`) são das duas.

---

## Caminho crítico

```
SET-6 (modelo de dados) → MED-1 (API de medicamentos) → MED-2 (gerar doses) → LEM-1 (lembrete local)
                                                                          → ESC-1/ESC-2 (agendador e regras) → ESC-3/ESC-4 (push ao cuidador)
```

Enquanto a API não fica pronta, o app e o painel usam dados de exemplo (`ENT-4`).

---

# E0 · Setup

### Título: `[SET-1] Estruturar o repositório`
**Labels:** `E0 · Setup` `docs` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Organizar o repositório para as três partes do projeto.

**O que fazer**
- [ ] Criar as pastas `api/` e `web/` dentro de `MVP/` ou na raiz (o app Flutter já está em `MVP/`)
- [ ] Adicionar `.gitignore` (Flutter, Node, Python, `.env*`)
- [ ] Criar o modelo de pull request em `.github/pull_request_template.md`
- [ ] Explicar no README como rodar cada parte

**Pronto quando:** a estrutura está na `main` e o README explica como rodar o projeto.
```

### Título: `[SET-2] Criar o projeto Flutter`
**Labels:** `E0 · Setup` `app` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Base do app usado por idosos e cuidadores.

**O que fazer**
- [x] Criar o projeto Flutter em `MVP/` (foco em Android)
- [ ] Definir o tema com as cores do mockup (verde para idoso, coral para cuidador)
- [ ] Fontes grandes por padrão, pensando em idosos
- [ ] Tela inicial com o logo do CuidarMais

**Pronto quando:** o app abre no emulador e em um celular Android com o tema do CuidarMais.
```

### Título: `[SET-3] Criar a API em Python com PostgreSQL`
**Labels:** `E0 · Setup` `api` `banco` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Base do backend único que atende o app e o painel.

**O que fazer**
- [ ] Criar o projeto FastAPI em `api/`
- [ ] Conectar ao PostgreSQL (local para desenvolver, plano gratuito para a demo)
- [ ] Configurar migrações do banco
- [ ] Rota `/saude` que responde OK
- [ ] Rodar os testes com pytest

**Pronto quando:** a API sobe localmente, conecta ao banco e a rota `/saude` responde.
```

### Título: `[SET-4] Criar o painel web em Next.js`
**Labels:** `E0 · Setup` `web` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Base do painel do médico.

**O que fazer**
- [ ] Criar o projeto Next.js com TypeScript em `web/`
- [ ] Definir as cores do mockup (violeta para o médico) e as fontes
- [ ] Página inicial com o logo do CuidarMais

**Pronto quando:** `npm run dev` abre a página inicial com o tema do CuidarMais.
```

### Título: `[SET-5] Configurar o Firebase Cloud Messaging`
**Labels:** `E0 · Setup` `push` `app` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Push gratuito, sem custo por mensagem e sem cartão de crédito.

**O que fazer**
- [ ] Criar o projeto no Firebase (plano gratuito) e ativar só o Cloud Messaging
- [ ] Adicionar o app Android e o arquivo de configuração no Flutter
- [ ] Pedir permissão de notificação no app
- [ ] Enviar uma notificação de teste pelo console do Firebase

**Pronto quando:** a notificação de teste chega no celular.
```

### Título: `[SET-6] Definir o modelo de dados`
**Labels:** `E0 · Setup` `banco` `docs` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Documentar as tabelas antes de programar.

**O que fazer**
- [ ] Escrever `docs/modelo-de-dados.md` com: `usuarios`, `idosos`, `vinculos`, `consentimentos`, `medicamentos`, `medicamentos_historico`, `doses`, `confirmacoes`, `alertas`, `dispositivos`
- [ ] Campos do medicamento: nome, dose, horários, dias, início, fim, prazo do alerta, origem (médico, família, paciente), criado por, criado em
- [ ] Estados da dose: `agendada`, `lembrada`, `adiada`, `tomada`, `alertada`, `tomada_apos_alerta`, `perdida`
- [ ] Na confirmação: horário real e quem confirmou (idoso ou cuidador)
- [ ] Diagrama das tabelas (pode ser mermaid)

**Pronto quando:** as duas revisaram e aprovaram o documento.
```

### Título: `[SET-7] Configurar integração contínua`
**Labels:** `E0 · Setup` `docs` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Verificações automáticas a cada pull request.

**O que fazer**
- [ ] GitHub Actions rodando os testes do Flutter
- [ ] Rodando os testes da API (pytest)
- [ ] Rodando lint e build do Next.js

**Pronto quando:** um pull request mostra o resultado das três verificações.
```

---

# E1 · Contas e vínculos

### Título: `[AUTH-1] API de cadastro e login com perfis`
**Labels:** `E1 · Contas e vínculos` `api` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Uma conta para cada pessoa, com o perfil dela.

**O que fazer**
- [ ] Rotas de cadastro e login (email e senha, senha com hash)
- [ ] Perfis: idoso, cuidador, médico
- [ ] Token de acesso nas demais rotas
- [ ] Testes

**Pronto quando:** os testes cobrem cadastro, login, senha errada e rota sem token.

**Depende de:** SET-3, SET-6
```

### Título: `[AUTH-2] Telas de login e cadastro no app`
**Labels:** `E1 · Contas e vínculos` `app` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Entrada no app para idosos e cuidadores.

**O que fazer**
- [ ] Tela de login
- [ ] Tela de cadastro com a escolha "Sou idoso" ou "Sou cuidador"
- [ ] Depois do login, abrir a área certa para cada perfil
- [ ] Botões e textos grandes

**Pronto quando:** um idoso e um cuidador criam conta e cada um cai na sua área.

**Depende de:** SET-2, AUTH-1
```

### Título: `[AUTH-3] Login do médico no painel web`
**Labels:** `E1 · Contas e vínculos` `web` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Acesso do médico ao painel.

**O que fazer**
- [ ] Tela de login
- [ ] Proteger as páginas do painel
- [ ] Botão de sair

**Pronto quando:** sem login, nenhuma página do painel abre.

**Depende de:** SET-4, AUTH-1
```

### Título: `[AUTH-4] API de convite por código`
**Labels:** `E1 · Contas e vínculos` `api` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Vínculo entre cuidador e idoso que usa o app, aceito dos dois lados.

**O que fazer**
- [ ] O cuidador gera um código de convite com validade de 24 horas
- [ ] O idoso informa o código e vê quem quer acompanhá-lo
- [ ] O vínculo só vale depois que o idoso aceita
- [ ] O idoso pode recusar e, depois, remover um vínculo

**Pronto quando:** os testes cobrem código válido, vencido, aceito e recusado.

**Depende de:** AUTH-1
```

### Título: `[AUTH-5] Telas de convite no app`
**Labels:** `E1 · Contas e vínculos` `app` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Os dois lados do convite, como no mockup.

**O que fazer**
- [ ] Cuidador: "Adicionar idoso" pergunta se ele usa o app; se sim, mostra o código
- [ ] Idoso: campo para digitar o código
- [ ] Idoso: pedido com Aceitar e Recusar, explicando o que o cuidador vai ver
- [ ] Idoso: tela "Quem me acompanha"

**Pronto quando:** um cuidador e um idoso se vinculam usando dois celulares.

**Depende de:** AUTH-2, AUTH-4
```

### Título: `[AUTH-6] Cadastro de idoso sem app`
**Labels:** `E1 · Contas e vínculos` `api` `app` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
O cuidador cadastra um idoso que não vai usar o celular.

**O que fazer**
- [ ] No "Adicionar idoso", opção "Não usa o app" com nome, nascimento e relação
- [ ] Idoso fica marcado como "sem app" e ligado ao cuidador
- [ ] Na API, os lembretes desse idoso vão para o cuidador

**Pronto quando:** o idoso sem app aparece na lista do cuidador.

**Depende de:** AUTH-4
```

### Título: `[AUTH-7] Vincular médico ao paciente`
**Labels:** `E1 · Contas e vínculos` `api` `web` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
O médico precisa ver os pacientes dele. A forma ainda precisa ser decidida.

**O que fazer**
- [ ] Decidir com a equipe: o médico adiciona pelo email do paciente ou o paciente informa um código do médico
- [ ] Implementar a opção escolhida na API
- [ ] Tela no painel para adicionar paciente

**Pronto quando:** o paciente aparece na lista do médico depois do vínculo.

**Depende de:** AUTH-3
```

### Título: `[AUTH-8] Consentimento e acesso por vínculo (LGPD)`
**Labels:** `E1 · Contas e vínculos` `api` `banco` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Dados de saúde são sensíveis: cada pessoa só vê o que pode ver.

**O que fazer**
- [ ] Tela de consentimento específico no cadastro, com data salva em `consentimentos`
- [ ] Médico só acessa os pacientes vinculados
- [ ] Cuidador só acessa os idosos vinculados
- [ ] Idoso só acessa os próprios dados
- [ ] Testes para cada regra

**Pronto quando:** os testes mostram que um cuidador não acessa idosos de outro.

**Depende de:** AUTH-4, AUTH-7
```

---

# E2 · Medicamentos

### Título: `[MED-1] API de medicamentos com origem e histórico`
**Labels:** `E2 · Medicamentos` `api` `banco` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Idoso, cuidador e médico cadastram pelo mesmo caminho, e o sistema guarda quem fez o quê.

**O que fazer**
- [ ] Criar, listar, editar e encerrar medicamentos
- [ ] Origem automática pelo perfil: médico = prescrição validada, cuidador = família, idoso = paciente
- [ ] Toda alteração gera um registro em `medicamentos_historico`
- [ ] Testes

**Pronto quando:** os testes cobrem as três origens e o histórico de uma edição.

**Depende de:** SET-6, AUTH-8
```

### Título: `[MED-2] Gerar as doses a partir do medicamento`
**Labels:** `E2 · Medicamentos` `api` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Transformar "Losartana às 08:00 todos os dias" em doses na agenda.

**O que fazer**
- [ ] Criar uma dose `agendada` para cada horário de cada dia
- [ ] Gerar os próximos 7 dias e completar diariamente
- [ ] Respeitar dias da semana e data de fim
- [ ] Ao editar, refazer as doses futuras; ao encerrar, cancelar
- [ ] Testes unitários

**Pronto quando:** os testes cobrem dias da semana, vários horários, data de fim e edição.

**Depende de:** MED-1
```

### Título: `[MED-3] Formulário de medicamento no app`
**Labels:** `E2 · Medicamentos` `app` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
O mesmo formulário para o idoso e para o cuidador.

**O que fazer**
- [ ] Campos: remédio, dose, horários, dias, início, fim
- [ ] Mensagem dizendo como o cadastro vai aparecer (por você / pela família)
- [ ] Lista "Meus remédios" com a origem de cada um
- [ ] Editar e encerrar

**Pronto quando:** um remédio cadastrado no app aparece na lista e gera as doses.

**Depende de:** MED-1, AUTH-2
```

### Título: `[MED-4] Formulário de medicamento no painel do médico`
**Labels:** `E2 · Medicamentos` `web` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Cadastro da prescrição de referência.

**O que fazer**
- [ ] Campos: remédio, dose, horários, dias, início, fim, prazo do alerta
- [ ] Prévia de como o lembrete chega para o idoso
- [ ] Editar e encerrar

**Pronto quando:** o remédio salvo pelo médico aparece no app do idoso como "Prescrito por".

**Depende de:** MED-1, AUTH-7
```

---

# E3 · Lembretes

### Título: `[LEM-1] Agendar os lembretes no aparelho`
**Labels:** `E3 · Lembretes` `app` `push` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
O lembrete toca mesmo sem internet.

**O que fazer**
- [ ] Baixar as doses dos próximos dias e agendar notificações locais (flutter_local_notifications)
- [ ] Reagendar quando um medicamento muda
- [ ] Reagendar ao reiniciar o celular
- [ ] Pedir permissão de alarme exato no Android

**Pronto quando:** um remédio cadastrado para daqui a 2 minutos toca com o celular em modo avião.

**Depende de:** MED-2, SET-5
```

### Título: `[LEM-2] Chat de lembretes do idoso`
**Labels:** `E3 · Lembretes` `app` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Tela principal do idoso, como no mockup.

**O que fazer**
- [ ] Uma mensagem por horário, com o remédio e a dose
- [ ] Cartão do lembrete atual com os botões grandes **Tomei** e **Me lembra em 15 min**
- [ ] Histórico do dia (o que já foi tomado)
- [ ] Tocar na notificação abre o chat no lembrete certo

**Pronto quando:** o idoso confirma uma dose pela notificação e pelo chat.

**Depende de:** LEM-1
```

### Título: `[LEM-3] API de confirmação "Tomei"`
**Labels:** `E3 · Lembretes` `api` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Registrar a dose tomada com segurança.

**O que fazer**
- [ ] Gravar o horário real e quem confirmou (idoso ou cuidador)
- [ ] Bloquear uma segunda confirmação da mesma dose
- [ ] Se a dose já estava alertada, marcar `tomada_apos_alerta` e encerrar o alerta
- [ ] Testes

**Pronto quando:** os testes cobrem confirmação normal, duplicada e após alerta.

**Depende de:** MED-2
```

### Título: `[LEM-4] "Me lembra em 15 min" até 2 vezes`
**Labels:** `E3 · Lembretes` `app` `api` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
O idoso pode adiar, mas só duas vezes.

**O que fazer**
- [ ] App: reagendar a notificação local para daqui a 15 minutos
- [ ] App: mostrar "Pode adiar mais 1 vez" e desativar o botão no limite
- [ ] API: registrar cada adiamento na dose
- [ ] API: no segundo adiamento, disparar o alerta ao cuidador (ESC-2)

**Pronto quando:** depois de 2 adiamentos o botão some e o cuidador recebe o alerta.

**Depende de:** LEM-2, LEM-3
```

### Título: `[LEM-5] Lista do dia em letras grandes`
**Labels:** `E3 · Lembretes` `app` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Visão simples do dia para o idoso.

**O que fazer**
- [ ] Horário, remédio e dose em fonte grande
- [ ] Marca de tomado, pendente e mais tarde
- [ ] Funcionar com o tamanho de fonte do sistema no máximo

**Pronto quando:** a lista é legível com a fonte do Android no tamanho máximo.

**Depende de:** MED-2
```

---

# E4 · Escalada

### Título: `[ESC-1] Agendador de tarefas`
**Labels:** `E4 · Escalada` `api` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Tarefa que roda a cada minuto no backend.

**O que fazer**
- [ ] Rota protegida que executa a verificação (pode ser chamada por um serviço de cron gratuito)
- [ ] Marcar como `lembrada` as doses cujo horário chegou
- [ ] Enviar push de reforço para quem ainda não confirmou
- [ ] Log de cada execução

**Pronto quando:** a tarefa roda a cada minuto e o log mostra as doses processadas.

**Depende de:** MED-2
```

### Título: `[ESC-2] Regras de alerta ao cuidador`
**Labels:** `E4 · Escalada` `api` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Quando o cuidador deve ser avisado.

**O que fazer**
- [ ] Alerta depois do segundo adiamento
- [ ] Alerta quando o idoso não responde dentro do prazo (valor configurável, ainda a definir)
- [ ] Um alerta por dose, sem repetir
- [ ] Criar o registro em `alertas` com o nome do remédio
- [ ] Testes para cada regra e para o limite do prazo

**Pronto quando:** os testes cobrem 2 adiamentos, sem resposta e confirmação antes do prazo.

**Depende de:** ESC-1, LEM-3
```

### Título: `[ESC-3] Enviar push ao cuidador`
**Labels:** `E4 · Escalada` `api` `push` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
O alerta chega no celular do cuidador.

**O que fazer**
- [ ] Guardar o token do Firebase de cada aparelho em `dispositivos`
- [ ] Enviar a notificação pelo Firebase Cloud Messaging: "Dona Maria adiou 2 vezes a Losartana 50 mg"
- [ ] Avisar quando o idoso confirmar depois do alerta
- [ ] Tratar token inválido

**Pronto quando:** o cuidador recebe o alerta no celular segundos depois do segundo adiamento.

**Depende de:** ESC-2, SET-5
```

### Título: `[ESC-4] Receber o alerta no app do cuidador`
**Labels:** `E4 · Escalada` `app` `push` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
Do alerta para a ação.

**O que fazer**
- [ ] Registrar o token do aparelho na API ao fazer login
- [ ] Tocar no alerta abre a tela do idoso
- [ ] Mostrar o alerta mesmo com o app fechado

**Pronto quando:** tocar no alerta abre a tela certa com o app fechado.

**Depende de:** ESC-3, CUI-1
```

### Título: `[ESC-5] Lembretes do idoso sem app vão para o cuidador`
**Labels:** `E4 · Escalada` `api` `push` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
O cuidador recebe o lembrete no lugar do idoso.

**O que fazer**
- [ ] No horário da dose, enviar o lembrete ao cuidador
- [ ] Repetir a cada 15 minutos até a confirmação
- [ ] Confirmação registrada como "feita pelo cuidador"

**Pronto quando:** o cuidador recebe avisos a cada 15 min até confirmar, e o relatório mostra quem confirmou.

**Depende de:** ESC-1, AUTH-6, LEM-3
```

---

# E5 · App do cuidador

### Título: `[CUI-1] Lista de idosos com status do dia`
**Labels:** `E5 · App do cuidador` `app` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Tela inicial do cuidador.

**O que fazer**
- [ ] Um cartão por idoso: nome, se usa o app, quantos remédios tomou hoje
- [ ] Faixa vermelha no topo quando há alerta aberto, com o nome do remédio
- [ ] Botão "Adicionar idoso"

**Pronto quando:** a faixa aparece quando o idoso adia 2 vezes e some quando ele confirma.

**Depende de:** CUI-4
```

### Título: `[CUI-2] Aba do idoso com app`
**Labels:** `E5 · App do cuidador` `app` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
O que o cuidador vê de cada idoso.

**O que fazer**
- [ ] Remédios de hoje com o estado de cada dose
- [ ] Últimos 7 dias
- [ ] Lista de remédios com origem, Cadastrar e Editar

**Pronto quando:** os dados batem com o que o idoso vê no app dele.

**Depende de:** CUI-4, MED-3
```

### Título: `[CUI-3] Aba do idoso sem app`
**Labels:** `E5 · App do cuidador` `app` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
O cuidador confirma pelo idoso, na mesma tela de lembretes.

**O que fazer**
- [ ] Reusar o chat de lembretes (LEM-2) na aba do idoso
- [ ] Aviso "Você recebe um aviso a cada 15 min até confirmar"
- [ ] Mensagem "Registrado como confirmado por você"

**Pronto quando:** o cuidador confirma uma dose e ela aparece como confirmada pelo cuidador.

**Depende de:** LEM-2, ESC-5
```

### Título: `[CUI-4] API do status do dia e dos 7 dias`
**Labels:** `E5 · App do cuidador` `api` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Dados para as telas do cuidador.

**O que fazer**
- [ ] Rota com os idosos vinculados e o status do dia de cada um
- [ ] Rota com as doses de hoje de um idoso
- [ ] Rota com o resumo dos últimos 7 dias

**Pronto quando:** os testes cobrem idoso com app, sem app e sem doses no dia.

**Depende de:** LEM-3, AUTH-8
```

---

# E6 · Painel do médico

### Título: `[DOC-1] Layout do painel do médico`
**Labels:** `E6 · Painel do médico` `web` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Estrutura comum das telas, como no mockup.

**O que fazer**
- [ ] Barra superior com logo, abas (Pacientes, Relatório, Cadastrar) e nome do médico
- [ ] Funcionar no computador e no tablet

**Pronto quando:** a navegação entre abas funciona.

**Depende de:** AUTH-3
```

### Título: `[DOC-2] Regra de classificação dos pacientes`
**Labels:** `E6 · Painel do médico` `api` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Decidir quem é vermelho, amarelo ou verde.

**O que fazer**
- [ ] Vermelho: alerta aberto hoje ou dose perdida de medicamento crítico
- [ ] Amarelo: confirmou só depois de alerta, adesão caindo, ou confirmações feitas pelo cuidador
- [ ] Verde: em dia
- [ ] Validar a regra com um médico (ENT-1)
- [ ] Testes

**Pronto quando:** os testes cobrem os três casos.

**Depende de:** ESC-2
```

### Título: `[DOC-3] Painel por exceção`
**Labels:** `E6 · Painel do médico` `web` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
O médico vê primeiro quem precisa de atenção, sem notificações.

**O que fazer**
- [ ] Três colunas: Precisam de atenção, Acompanhar, Em dia
- [ ] Cada paciente com % de adesão e o motivo em uma linha
- [ ] Atualizar ao abrir e a cada minuto

**Pronto quando:** um paciente que adiou 2 vezes aparece em vermelho em até 1 minuto.

**Depende de:** DOC-1, DOC-2
```

### Título: `[DOC-4] Cálculo de adesão por período`
**Labels:** `E6 · Painel do médico` `api` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Base do relatório do médico e do histórico do cuidador.

**O que fazer**
- [ ] Contar doses tomadas no horário, tomadas após adiar ou alerta, e perdidas
- [ ] Separar por período: manhã, tarde, noite
- [ ] Separar confirmações do idoso e do cuidador
- [ ] Testes com 0%, 100% e dias sem dose

**Pronto quando:** os testes passam.

**Depende de:** LEM-3
```

### Título: `[DOC-5] Relatório de adesão do paciente`
**Labels:** `E6 · Painel do médico` `web` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
O médico avalia o tratamento.

**O que fazer**
- [ ] Anel com a adesão de 14 dias
- [ ] Mapa de 14 dias por período do dia
- [ ] Linha do tempo de uma dose (lembrete, adiamentos, alerta, confirmação)
- [ ] Medicamentos com a origem de cada um

**Pronto quando:** os números batem com os dados de demonstração.

**Depende de:** DOC-4
```

---

# E7 · Depois do MVP

### Título: `[DEP-1] Fila de revisão do médico`
**Labels:** `E7 · Depois do MVP` `web` `api` `depois`

**Descrição:**
```markdown
Medicamentos cadastrados pela família ou pelo idoso chegam ao médico como pendentes de revisão, e ele valida, corrige ou recusa.
```

### Título: `[DEP-2] Cadastro por foto da receita`
**Labels:** `E7 · Depois do MVP` `app` `api` `depois`

**Descrição:**
```markdown
Fotografar a receita e extrair remédio, dose e horário com OCR + NLP, com tela de revisão antes de salvar.
```

### Título: `[DEP-3] Detecção de padrões de esquecimento`
**Labels:** `E7 · Depois do MVP` `api` `web` `depois`

**Descrição:**
```markdown
Mostrar no relatório quando o paciente esquece sempre no mesmo período (por exemplo, o remédio da tarde).
```

### Título: `[DEP-4] Checagem de alergias e controle de estoque`
**Labels:** `E7 · Depois do MVP` `api` `depois`

**Descrição:**
```markdown
Avisar quando um remédio conflita com uma alergia registrada e quando a caixa está acabando.
```

### Título: `[DEP-5] Distinguir "sem resposta" de "app inacessível"`
**Labels:** `E7 · Depois do MVP` `app` `api` `depois`

**Descrição:**
```markdown
Evitar alerta falso quando o celular está sem bateria, sem internet ou sem permissão de notificação. Usar o último contato do aparelho com a API para diferenciar.
```

### Título: `[DEP-6] Versão para iPhone`
**Labels:** `E7 · Depois do MVP` `app` `push` `depois`

**Descrição:**
```markdown
Publicar o app para iOS. Exige conta de desenvolvedor da Apple (paga) e um Mac.
```

---

# E8 · Entregáveis

### Título: `[ENT-1] Pesquisa com médicos e cuidadores`
**Labels:** `E8 · Entregáveis` `docs` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Validar o problema e as regras de alerta com quem vai usar.

**O que fazer**
- [ ] Roteiro curto de perguntas, incluindo quando querem ser avisados
- [ ] Conversar com 2 ou 3 médicos e 2 ou 3 cuidadores
- [ ] Definir o prazo do alerta "sem resposta"
- [ ] Conferir a fonte do dado de que cerca de 50% dos idosos não seguem as prescrições
- [ ] Resumir em `docs/pesquisa.md`

**Pronto quando:** o resumo responde o prazo do alerta e lista o que muda no escopo.
```

### Título: `[ENT-2] Protótipo das telas`
**Labels:** `E8 · Entregáveis` `docs` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Prototipação do app (idoso e cuidador) e do painel do médico.

**O que fazer**
- [ ] Revisar o protótipo (`prototipo/index.html`) com o que a pesquisa mostrou
- [ ] Passar para o Figma, se a mentoria pedir
- [ ] Mostrar para 1 ou 2 idosos e anotar dificuldades

**Pronto quando:** o protótipo reflete a pesquisa e foi testado com pelo menos 1 idoso.

**Depende de:** ENT-1
```

### Título: `[ENT-3] Business Model Canvas`
**Labels:** `E8 · Entregáveis` `docs` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Entregável do SuperNova.

**O que fazer**
- [ ] Preencher o canvas a partir da seção "Modelo de negócio e custos" do documento
- [ ] Ajustar com o que a pesquisa mostrou
- [ ] Salvar no repositório (imagem ou PDF)

**Pronto quando:** o canvas está no repositório.
```

### Título: `[ENT-4] Dados de demonstração`
**Labels:** `E8 · Entregáveis` `banco` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Dados realistas para desenvolver as telas e gravar a demo.

**O que fazer**
- [ ] Script que cria a Dra. Helena, Dona Maria (com app), Seu Antônio (sem app), Carla (cuidadora) e mais 3 pacientes
- [ ] 14 dias de histórico com adiamentos, alertas e esquecimentos
- [ ] Um comando para apagar e recriar tudo

**Pronto quando:** um comando recria o ambiente de demonstração do zero.

**Depende de:** SET-6
```

### Título: `[ENT-5] Testes com usuários reais`
**Labels:** `E8 · Entregáveis` `docs` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
Rodar o fluxo completo em celulares de verdade.

**O que fazer**
- [ ] Roteiro: cadastrar remédio → lembrete → adiar 2 vezes → cuidador recebe alerta → médico vê no painel
- [ ] Testar também o idoso sem app
- [ ] Testar com pelo menos 1 idoso e 1 cuidador reais
- [ ] Anotar problemas e corrigir

**Pronto quando:** o roteiro passa duas vezes seguidas sem ajuste manual.

**Depende de:** ESC-4, CUI-3, DOC-3
```

### Título: `[ENT-6] Vídeo-pitch de 3 minutos`
**Labels:** `E8 · Entregáveis` `docs` `mvp` · **Milestone:** Semana 6

**Descrição:**
```markdown
Entregável final do SuperNova.

**O que fazer**
- [ ] Roteiro: problema, solução, demo, diferenciais, modelo de negócio
- [ ] Gravar a demo do fluxo nos celulares e no painel
- [ ] Editar e revisar o tempo (até 3 min)

**Pronto quando:** o vídeo está enviado na plataforma do SuperNova.

**Depende de:** ENT-5
```

### Título: `[ENT-7] Consulta sobre LGPD e Anvisa`
**Labels:** `E8 · Entregáveis` `docs` `depois`

**Descrição:**
```markdown
Pontos em aberto do documento, para antes de operar com pacientes reais.

**O que fazer**
- [ ] Quem consente pelo idoso que não decide por si
- [ ] Enquadramento do app na RDC 657/2022 da Anvisa
- [ ] Registrar as respostas em `docs/decisoes.md`
```

---

## Resumo por semana e por frente

| Semana | Frente App | Frente API + Web | Juntas |
|---|---|---|---|
| 1 | SET-2, SET-5 | SET-3, SET-4, SET-7 | SET-1, SET-6, ENT-1 |
| 2 | AUTH-2, AUTH-5 | AUTH-1, AUTH-3, AUTH-4, AUTH-7 | AUTH-6, ENT-2, ENT-3 |
| 3 | MED-3, LEM-1 | AUTH-8, MED-1, MED-2, LEM-3, ESC-1, ESC-2 | ENT-4 |
| 4 | LEM-2, LEM-5, CUI-1, CUI-2 | MED-4, CUI-4, DOC-1, DOC-2, DOC-3, DOC-4 | LEM-4 |
| 5 | ESC-4, CUI-3 | ESC-3, ESC-5, DOC-5 | ENT-5 |
| 6 | ajustes | ajustes | ENT-6 |

A frente API + Web tem mais tarefas nas semanas 3 e 4. Se apertar, a Frente App pode assumir `CUI-4` ou `DOC-4`, ou o painel do médico pode usar os dados de demonstração (`ENT-4`) até a API ficar pronta.
