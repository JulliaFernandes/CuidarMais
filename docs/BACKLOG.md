# Backlog do Cuidar+

Cada tarefa abaixo vira **uma issue** no GitHub. Para cada uma:

1. Copie o **Título** para o título da issue.
2. Copie o bloco **Descrição** para o corpo da issue.
3. Marque as **Labels** e o **Milestone** indicados.
4. Adicione a issue ao board na coluna **Backlog**.

---

## Labels para criar no GitHub

Crie em **Issues → Labels → New label**. As cores são sugestões.

**Épico** (de qual parte do projeto é a tarefa)

| Label | Cor | Descrição |
|---|---|---|
| `E0 · Setup` | `#6B6485` | Estrutura do projeto e contas |
| `E1 · Contas` | `#6A4DF4` | Login, papéis e vínculos |
| `E2 · Medicamentos` | `#8E6CFF` | Cadastro de remédios e geração de doses |
| `E3 · WhatsApp` | `#17914F` | Lembrete e confirmação |
| `E4 · Alertas` | `#D7263F` | Atraso e aviso ao cuidador |
| `E5 · Painel médico` | `#4A35C8` | Telas web do médico |
| `E6 · Painel cuidador` | `#EF5B33` | Telas web do cuidador |
| `E7 · Diferenciais` | `#F5B729` | Extras depois do MVP |
| `E8 · Entregáveis` | `#221B3A` | Pesquisa, canvas, demo e pitch |

**Área** (que tipo de trabalho é)

| Label | Cor | Descrição |
|---|---|---|
| `web` | `#C9BDFF` | Telas do Next.js |
| `back-end` | `#FFC2AE` | Funções, agendador e regras de negócio |
| `whatsapp` | `#A8E6C1` | Integração com a WhatsApp Cloud API |
| `banco` | `#FFE08A` | Tabelas, políticas de acesso e dados |
| `ia` | `#E6E1F2` | OCR e análise de padrões |
| `docs` | `#D6DFEA` | Documentação e entregáveis |

**Prioridade**

| Label | Cor | Descrição |
|---|---|---|
| `mvp` | `#0F6B45` | Necessário para o fluxo completo da demo |
| `extra` | `#B97A00` | Só se sobrar tempo |

**Milestones** (crie em **Issues → Milestones**): `Semana 1`, `Semana 2`, `Semana 3`, `Semana 4`, `Semana 5`, `Semana 6`.

---

## Caminho crítico

O WhatsApp depende da aprovação da Meta e de todo o back-end funcionando junto. Comecem por ele:

```
SET-5 (conta Meta) → WPP-1 (modelos aprovados) → WPP-2 (enviar) → WPP-3 (agendador)
                                                               ↘ WPP-4 (webhook) → WPP-5 (Tomei) → ALR-1/ALR-2 (alertas)
```

Os painéis web podem ser feitos em paralelo com dados de exemplo (`ENT-3`).

---

# E0 · Setup

### Título: `[SET-1] Estruturar o repositório`
**Labels:** `E0 · Setup` `docs` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Organizar o repositório para as duas partes do projeto.

**O que fazer**
- [ ] Criar as pastas `web/`, `supabase/` e `docs/`
- [ ] Adicionar `.gitignore` (Node, Next.js, `.env*`)
- [ ] Criar o modelo de pull request em `.github/pull_request_template.md`
- [ ] Explicar no README como rodar cada parte

**Pronto quando:** a estrutura está na `main` e o README explica como rodar o projeto.
```

### Título: `[SET-2] Criar o projeto web em Next.js`
**Labels:** `E0 · Setup` `web` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Criar o projeto web que vai ter os painéis do médico e do cuidador.

**O que fazer**
- [ ] Criar o projeto Next.js com TypeScript em `web/`
- [ ] Definir as cores do mockup como variáveis de tema (violeta, coral, verde, amarelo)
- [ ] Configurar as fontes Bricolage Grotesque e Nunito Sans
- [ ] Criar uma página inicial simples com o logo do Cuidar+

**Pronto quando:** `npm run dev` abre a página inicial com o tema do Cuidar+.

**Depende de:** SET-1
```

### Título: `[SET-3] Criar o projeto no Supabase`
**Labels:** `E0 · Setup` `banco` `back-end` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Criar o back-end gratuito (banco, login e funções), que não pede cartão de crédito.

**O que fazer**
- [ ] Criar o projeto no plano gratuito do Supabase
- [ ] Ativar o login por email e senha
- [ ] Instalar o Supabase CLI e iniciar a pasta `supabase/`
- [ ] Guardar as chaves em `web/.env.local` (fora do Git) e documentar no README

**Pronto quando:** a página web lê e escreve um registro de teste no banco.

**Depende de:** SET-2
```

### Título: `[SET-4] Configurar integração contínua`
**Labels:** `E0 · Setup` `docs` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Rodar verificações automáticas a cada pull request.

**O que fazer**
- [ ] Criar o workflow do GitHub Actions
- [ ] Rodar lint, testes e build do projeto web

**Pronto quando:** um pull request mostra o resultado das verificações.

**Depende de:** SET-2
```

### Título: `[SET-5] Criar a conta na WhatsApp Cloud API`
**Labels:** `E0 · Setup` `whatsapp` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
⚠️ Começar logo: o resto do WhatsApp depende desta tarefa.

**O que fazer**
- [ ] Criar um app em developers.facebook.com e adicionar o produto WhatsApp
- [ ] Anotar o número de teste, o ID do número e o token
- [ ] Cadastrar os celulares da Júllia e da Anna como destinatários de teste (máximo 5)
- [ ] Enviar a mensagem de teste `hello_world`
- [ ] Guardar o token em lugar seguro (nunca no Git)

**Pronto quando:** a mensagem `hello_world` chega no celular de uma de nós.
```

### Título: `[SET-6] Definir o modelo de dados`
**Labels:** `E0 · Setup` `banco` `docs` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Documentar as tabelas antes de começar a programar.

**O que fazer**
- [ ] Escrever `docs/modelo-de-dados.md` com as tabelas: `perfis`, `pacientes`, `cuidadores_pacientes`, `medicamentos`, `doses`, `alertas`
- [ ] Definir os estados da dose: `agendada`, `enviada`, `tomada`, `atrasada`, `tomada_atrasada`, `perdida`
- [ ] Desenhar o diagrama das tabelas (pode ser mermaid)

**Pronto quando:** as duas revisaram e aprovaram o documento.
```

---

# E1 · Contas

### Título: `[AUTH-1] Telas de login, cadastro e recuperar senha`
**Labels:** `E1 · Contas` `web` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Permitir que médicos e cuidadores criem conta e entrem no sistema.

**O que fazer**
- [ ] Tela de login com email e senha
- [ ] Tela de cadastro escolhendo o papel: médico ou cuidador
- [ ] Tela "Esqueci minha senha"
- [ ] Mensagens de erro claras (senha errada, email já usado)

**Pronto quando:** um médico cria conta, sai e entra de novo.

**Depende de:** SET-2, SET-3
```

### Título: `[AUTH-2] Proteger as páginas por papel`
**Labels:** `E1 · Contas` `web` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Cada pessoa só acessa a área dela.

**O que fazer**
- [ ] Médico vai para `/medico` depois do login
- [ ] Cuidador vai para `/familia` depois do login
- [ ] Quem não está logado volta para o login

**Pronto quando:** um cuidador não consegue abrir nenhuma página do médico.

**Depende de:** AUTH-1
```

### Título: `[AUTH-3] Médico cadastra paciente`
**Labels:** `E1 · Contas` `web` `banco` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
O médico cadastra o paciente que vai receber os lembretes.

**O que fazer**
- [ ] Formulário com nome, data de nascimento, telefone do WhatsApp, condições e alergias
- [ ] Validar o telefone no formato internacional (+55 DDD número)
- [ ] Salvar o paciente ligado ao médico que cadastrou
- [ ] Mostrar o paciente na lista do médico

**Pronto quando:** o paciente aparece na lista e telefones inválidos são recusados.

**Depende de:** AUTH-2, SET-6
```

### Título: `[AUTH-4] Vincular cuidador ao paciente`
**Labels:** `E1 · Contas` `web` `banco` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Ligar o familiar à pessoa de quem ele cuida.

**O que fazer**
- [ ] Na página do paciente, o médico informa nome, email e telefone do cuidador
- [ ] Quando o cuidador cria conta com esse email, o vínculo é feito
- [ ] O cuidador vê o paciente no painel dele

**Pronto quando:** o cuidador logado vê só os pacientes vinculados a ele.

**Depende de:** AUTH-3
```

### Título: `[AUTH-5] Políticas de acesso ao banco`
**Labels:** `E1 · Contas` `banco` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Garantir no banco que ninguém vê dados de quem não deveria.

**O que fazer**
- [ ] Ativar Row Level Security em todas as tabelas
- [ ] Médico lê e edita só os pacientes dele
- [ ] Cuidador lê só os pacientes vinculados
- [ ] A tabela `doses` só é alterada pelas funções do servidor

**Pronto quando:** testamos com dois médicos e um não vê os pacientes do outro.

**Depende de:** AUTH-4
```

---

# E2 · Medicamentos

### Título: `[MED-1] Formulário de medicamento`
**Labels:** `E2 · Medicamentos` `web` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Etapa 1 do fluxo: o médico cadastra o remédio do paciente.

**O que fazer**
- [ ] Campos: nome, dose, horários, dias da semana, início, fim
- [ ] Campo "Avisar o cuidador se não confirmar em" (15, 30 ou 60 min)
- [ ] Salvar e mostrar na página do paciente

**Pronto quando:** o medicamento salvo aparece na página do paciente.

**Depende de:** AUTH-3
```

### Título: `[MED-2] Validações do formulário de medicamento`
**Labels:** `E2 · Medicamentos` `web` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Evitar cadastros errados.

**O que fazer**
- [ ] Data de fim antes da data de início
- [ ] Nenhum horário escolhido
- [ ] Nenhum dia da semana marcado
- [ ] Testes para cada caso

**Pronto quando:** cada caso mostra uma mensagem clara e tem teste.

**Depende de:** MED-1
```

### Título: `[MED-3] Prévia da mensagem do WhatsApp`
**Labels:** `E2 · Medicamentos` `web` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Mostrar ao médico como o lembrete vai chegar para o paciente.

**O que fazer**
- [ ] Balão de mensagem ao lado do formulário, como no mockup
- [ ] Texto atualiza enquanto o médico digita nome e dose
- [ ] Mostrar os botões "Tomei" e "Me lembra em 15 min"

**Pronto quando:** a prévia muda enquanto o médico digita.

**Depende de:** MED-1
```

### Título: `[MED-4] Gerar as doses a partir do medicamento`
**Labels:** `E2 · Medicamentos` `back-end` `banco` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Transformar "Losartana às 08:00 todos os dias" em doses concretas na agenda.

**O que fazer**
- [ ] Função que cria um registro em `doses` para cada horário de cada dia, com estado `agendada`
- [ ] Gerar os próximos 7 dias ao salvar o medicamento
- [ ] Rodar uma vez por dia para gerar o dia seguinte
- [ ] Respeitar dias da semana e data de fim
- [ ] Testes unitários

**Pronto quando:** os testes cobrem dias da semana, vários horários e data de fim.

**Depende de:** MED-1, SET-6
```

### Título: `[MED-5] Editar e encerrar medicamento`
**Labels:** `E2 · Medicamentos` `web` `back-end` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Permitir que o médico mude ou pare um tratamento.

**O que fazer**
- [ ] Botão Editar abre o formulário preenchido
- [ ] Ao editar, as doses futuras são refeitas
- [ ] Botão Encerrar cancela as doses futuras

**Pronto quando:** mudar um horário altera os próximos lembretes.

**Depende de:** MED-4
```

### Título: `[MED-6] Aviso de alergia ao cadastrar medicamento`
**Labels:** `E2 · Medicamentos` `web` `extra` · **Milestone:** Semana 4

**Descrição:**
```markdown
Avisar o médico quando o remédio pode causar alergia no paciente.

**O que fazer**
- [ ] Tabela simples de classes (ex.: amoxicilina → penicilinas)
- [ ] Comparar com as alergias do paciente
- [ ] Mostrar aviso vermelho no formulário, sem impedir o cadastro

**Pronto quando:** cadastrar amoxicilina para quem tem alergia a penicilina mostra o aviso.

**Depende de:** MED-1
```

---

# E3 · WhatsApp

### Título: `[WPP-1] Criar os modelos de mensagem e enviar para aprovação`
**Labels:** `E3 · WhatsApp` `whatsapp` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
O WhatsApp só deixa a empresa iniciar conversa com modelos aprovados.

**O que fazer**
- [ ] Modelo `lembrete_remedio` (categoria Utilidade) com variáveis: nome, remédio, dose
- [ ] Botões de resposta rápida: "✅ Tomei" e "⏰ Me lembra em 15 min"
- [ ] Modelo `alerta_cuidador` com variáveis: paciente, remédio, horário
- [ ] Botão de resposta rápida: "📞 Já falei com ela"
- [ ] Enviar os dois para aprovação

**Pronto quando:** os dois modelos aparecem como aprovados no painel da Meta.

**Depende de:** SET-5
```

### Título: `[WPP-2] Função para enviar mensagem no WhatsApp`
**Labels:** `E3 · WhatsApp` `back-end` `whatsapp` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Módulo reutilizável que envia um modelo para um telefone.

**O que fazer**
- [ ] Função `enviarModelo(telefone, modelo, variaveis)` chamando a WhatsApp Cloud API
- [ ] Guardar o ID da mensagem enviada junto da dose
- [ ] Registrar erros (número inválido, token vencido)
- [ ] Token lido de variável de ambiente

**Pronto quando:** um teste manual envia o lembrete real para o celular de uma de nós.

**Depende de:** WPP-1, SET-3
```

### Título: `[WPP-3] Agendador que envia os lembretes`
**Labels:** `E3 · WhatsApp` `back-end` `mvp` · **Milestone:** Semana 3

**Descrição:**
```markdown
Etapa 2 do fluxo: o lembrete chega na hora certa.

**O que fazer**
- [ ] Tarefa agendada (pg_cron do Supabase) que roda a cada minuto
- [ ] Buscar doses `agendada` com horário já vencido
- [ ] Enviar o lembrete com WPP-2 e mudar o estado para `enviada`
- [ ] Não enviar a mesma dose duas vezes

**Pronto quando:** um remédio cadastrado para daqui a 2 minutos chega no WhatsApp na hora certa.

**Depende de:** WPP-2, MED-4
```

### Título: `[WPP-4] Webhook para receber as respostas do WhatsApp`
**Labels:** `E3 · WhatsApp` `back-end` `whatsapp` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Endereço onde a Meta avisa que o paciente tocou em um botão.

**O que fazer**
- [ ] Função HTTP (Supabase Edge Function) pública
- [ ] Responder à verificação da Meta (GET com `hub.challenge`)
- [ ] Receber as respostas (POST) e registrar no log
- [ ] Cadastrar a URL no painel da Meta

**Pronto quando:** tocar em um botão no celular gera um registro no log da função.

**Depende de:** WPP-2
```

### Título: `[WPP-5] Registrar quando o paciente toca em "Tomei"`
**Labels:** `E3 · WhatsApp` `back-end` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Etapa 3 do fluxo: a confirmação com um toque.

**O que fazer**
- [ ] Achar a dose pelo ID da mensagem respondida
- [ ] Marcar `tomada` (ou `tomada_atrasada` se já estava `atrasada`) com o horário
- [ ] Responder "Registrado! Próximo: ..." para o paciente
- [ ] Se havia alerta aberto, avisar o cuidador que ela tomou

**Pronto quando:** a dose aparece como tomada no banco e o paciente recebe a resposta.

**Depende de:** WPP-4
```

### Título: `[WPP-6] Tratar "Me lembra em 15 min"`
**Labels:** `E3 · WhatsApp` `back-end` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Permitir que o paciente adie o lembrete uma vez.

**O que fazer**
- [ ] Reagendar a dose para 15 minutos depois
- [ ] Permitir adiar só uma vez por dose
- [ ] Responder "Combinado! Te chamo às HH:MM"

**Pronto quando:** o lembrete chega de novo 15 minutos depois.

**Depende de:** WPP-4
```

### Título: `[WPP-7] Pedir consentimento do paciente`
**Labels:** `E3 · WhatsApp` `whatsapp` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
O WhatsApp exige que a pessoa aceite receber mensagens.

**O que fazer**
- [ ] Modelo de boas-vindas explicando o Cuidar+ com botão "Aceito"
- [ ] Enviar ao cadastrar o paciente
- [ ] Só enviar lembretes para quem aceitou
- [ ] Mostrar na página do paciente se ele já aceitou

**Pronto quando:** só pacientes que aceitaram recebem lembretes.

**Depende de:** WPP-2
```

---

# E4 · Alertas

### Título: `[ALR-1] Detectar dose sem resposta`
**Labels:** `E4 · Alertas` `back-end` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Etapa 4 do fluxo: perceber que o paciente não confirmou.

**O que fazer**
- [ ] Tarefa agendada a cada minuto
- [ ] Doses `enviada` que passaram do prazo do alerta viram `atrasada`
- [ ] Criar um registro em `alertas` para cada uma
- [ ] Testes para o limite do prazo (29, 30 e 31 minutos)

**Pronto quando:** os testes do limite passam e o alerta é criado no banco.

**Depende de:** WPP-3
```

### Título: `[ALR-2] Enviar alerta ao cuidador no WhatsApp`
**Labels:** `E4 · Alertas` `back-end` `whatsapp` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
Avisar o familiar quando o paciente não confirma.

**O que fazer**
- [ ] Enviar o modelo `alerta_cuidador` para cada cuidador vinculado
- [ ] Avisar o paciente: "Avisamos a Carla para te ligar"
- [ ] Guardar o ID da mensagem no alerta

**Pronto quando:** o cuidador recebe o alerta 30 min depois de um lembrete sem resposta.

**Depende de:** ALR-1, WPP-1
```

### Título: `[ALR-3] Resolver alerta`
**Labels:** `E4 · Alertas` `back-end` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
Registrar que alguém cuidou da situação.

**O que fazer**
- [ ] "Já falei com ela" no WhatsApp marca o alerta como resolvido
- [ ] O mesmo botão no painel faz a mesma coisa
- [ ] Guardar quem resolveu e quando

**Pronto quando:** o alerta some dos pendentes nos dois painéis.

**Depende de:** ALR-2
```

### Título: `[ALR-4] Marcar doses perdidas no fim do dia`
**Labels:** `E4 · Alertas` `back-end` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
Fechar o dia para o relatório ficar correto.

**O que fazer**
- [ ] Tarefa diária às 23:59
- [ ] Doses ainda `enviada` ou `atrasada` viram `perdida`

**Pronto quando:** o relatório conta essas doses como perdidas.

**Depende de:** ALR-1
```

### Título: `[ALR-5] Resumo diário para o cuidador`
**Labels:** `E4 · Alertas` `whatsapp` `extra` · **Milestone:** Semana 6

**Descrição:**
```markdown
Dar tranquilidade ao familiar mesmo quando está tudo bem.

**O que fazer**
- [ ] Modelo `resumo_diario`: "Dona Maria tomou 4 de 4 remédios hoje"
- [ ] Enviar às 21:00 para cada cuidador

**Pronto quando:** o resumo chega com os números corretos.

**Depende de:** ALR-4
```

---

# E5 · Painel médico

### Título: `[DOC-1] Layout do painel do médico`
**Labels:** `E5 · Painel médico` `web` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Estrutura comum de todas as telas do médico, como no mockup.

**O que fazer**
- [ ] Barra superior com logo, abas (Visão geral, Pacientes, Cadastrar) e nome do médico
- [ ] Área de conteúdo
- [ ] Funcionar no computador e no celular

**Pronto quando:** a navegação entre abas funciona nos dois tamanhos de tela.

**Depende de:** AUTH-2
```

### Título: `[DOC-2] Lista de pacientes com adesão`
**Labels:** `E5 · Painel médico` `web` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Ver todos os pacientes e quem está seguindo o tratamento.

**O que fazer**
- [ ] Tabela com nome, idade, condições
- [ ] Últimos 7 dias em quadradinhos coloridos
- [ ] Porcentagem de adesão com cor (verde, amarelo, vermelho)
- [ ] Busca por nome

**Pronto quando:** clicar em um paciente abre o relatório dele.

**Depende de:** DOC-1, DOC-5
```

### Título: `[DOC-3] Régua do dia`
**Labels:** `E5 · Painel médico` `web` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Ver de relance as doses de hoje de todos os pacientes.

**O que fazer**
- [ ] Uma linha por paciente, eixo de 06h a 22h
- [ ] Uma bolinha por dose, colorida pelo estado
- [ ] Atualizar em tempo real (Supabase Realtime)

**Pronto quando:** confirmar no WhatsApp muda a cor da bolinha sem recarregar a página.

**Depende de:** DOC-1
```

### Título: `[DOC-4] Lista "Precisam de atenção"`
**Labels:** `E5 · Painel médico` `web` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
Mostrar ao médico o que precisa de ação.

**O que fazer**
- [ ] Alertas abertos primeiro (vermelho)
- [ ] Depois avisos menores (amarelo)
- [ ] Atualizar em tempo real

**Pronto quando:** um alerta novo aparece no topo sem recarregar a página.

**Depende de:** ALR-1
```

### Título: `[DOC-5] Cálculo de adesão`
**Labels:** `E5 · Painel médico` `back-end` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Base dos números dos dois painéis.

**O que fazer**
- [ ] Função que conta doses tomadas, atrasadas e perdidas em N dias
- [ ] Separar por período: manhã, tarde, noite
- [ ] Calcular a porcentagem
- [ ] Testes com 0%, 100% e dias sem dose

**Pronto quando:** os testes passam.

**Depende de:** MED-4
```

### Título: `[DOC-6] Relatório do paciente`
**Labels:** `E5 · Painel médico` `web` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
Etapa 5 do fluxo: o médico avalia o tratamento.

**O que fazer**
- [ ] Anel com a porcentagem de adesão de 14 dias
- [ ] Mapa de 14 dias por período (manhã, tarde, noite)
- [ ] Lista de medicamentos ativos com o estado de hoje
- [ ] Cuidadores vinculados

**Pronto quando:** os números batem com os dados de demonstração.

**Depende de:** DOC-5
```

---

# E6 · Painel cuidador

### Título: `[CAR-1] Checklist do dia no painel do cuidador`
**Labels:** `E6 · Painel cuidador` `web` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
O cuidador vê como está o dia de quem ele acompanha.

**O que fazer**
- [ ] Um cartão por pessoa vinculada
- [ ] Horários do dia com o estado de cada dose
- [ ] Atualizar em tempo real

**Pronto quando:** o checklist muda sozinho quando o paciente confirma.

**Depende de:** AUTH-4
```

### Título: `[CAR-2] Faixa de alerta no painel do cuidador`
**Labels:** `E6 · Painel cuidador` `web` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
Destaque para quando algo deu errado.

**O que fazer**
- [ ] Faixa vermelha no topo com o alerta aberto
- [ ] Telefone do paciente visível
- [ ] Botão "Já falei com ela"

**Pronto quando:** resolver pelo painel também resolve no WhatsApp e no painel do médico.

**Depende de:** ALR-1, ALR-3
```

### Título: `[CAR-3] Últimos 7 dias no painel do cuidador`
**Labels:** `E6 · Painel cuidador` `web` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
Resumo da semana para o familiar.

**O que fazer**
- [ ] Sete círculos coloridos (um por dia)
- [ ] Porcentagem de adesão da semana

**Pronto quando:** os valores batem com o relatório do médico.

**Depende de:** DOC-5
```

---

# E7 · Diferenciais

### Título: `[EXT-1] Cadastro por foto da receita`
**Labels:** `E7 · Diferenciais` `ia` `extra` · **Milestone:** Semana 6

**Descrição:**
```markdown
Diferencial do documento: tirar foto da receita em vez de digitar.

**O que fazer**
- [ ] Enviar a foto da receita
- [ ] Extrair remédio, dose e horário (OCR + modelo de linguagem)
- [ ] Tela de revisão com nível de confiança de cada campo
- [ ] Preencher o formulário de medicamento

**Pronto quando:** uma receita impressa de exemplo preenche o formulário corretamente.
```

### Título: `[EXT-2] Detectar padrão de esquecimento`
**Labels:** `E7 · Diferenciais` `ia` `extra` · **Milestone:** Semana 6

**Descrição:**
```markdown
Mostrar ao médico quando o paciente esquece sempre no mesmo período.

**O que fazer**
- [ ] Regra: período com mais de 30% de doses perdidas em 14 dias
- [ ] Aviso no relatório com sugestão de ajuste

**Pronto quando:** o aviso aparece para os dados de demonstração.

**Depende de:** DOC-5
```

### Título: `[EXT-3] Página simples do paciente`
**Labels:** `E7 · Diferenciais` `web` `extra`

**Descrição:**
```markdown
Para quem prefere não usar o WhatsApp.

**O que fazer**
- [ ] Próxima dose em letras grandes
- [ ] Botão "Tomei"
- [ ] Lista do dia

**Pronto quando:** confirmar pela página tem o mesmo efeito que pelo WhatsApp.
```

### Título: `[EXT-4] Controle de estoque e reposição`
**Labels:** `E7 · Diferenciais` `back-end` `extra`

**Descrição:**
```markdown
Avisar quando o remédio está acabando.

**O que fazer**
- [ ] Quantidade na caixa diminui a cada dose tomada
- [ ] Aviso quando faltam 5 dias

**Pronto quando:** o aviso aparece em "Precisam de atenção".
```

---

# E8 · Entregáveis

### Título: `[ENT-1] Pesquisa com médicos e cuidadores`
**Labels:** `E8 · Entregáveis` `docs` `mvp` · **Milestone:** Semana 1

**Descrição:**
```markdown
Validar o problema com quem vai usar.

**O que fazer**
- [ ] Escrever um roteiro curto de perguntas
- [ ] Conversar com pelo menos 5 pessoas (médicos e cuidadores)
- [ ] Resumir em `docs/pesquisa.md`

**Pronto quando:** o resumo lista o que confirma e o que muda no escopo.
```

### Título: `[ENT-2] Business Model Canvas`
**Labels:** `E8 · Entregáveis` `docs` `mvp` · **Milestone:** Semana 2

**Descrição:**
```markdown
Entregável do SuperNova.

**O que fazer**
- [ ] Preencher o canvas a partir da seção 7 do documento do projeto
- [ ] Ajustar com o que a pesquisa mostrou
- [ ] Salvar no repositório (imagem ou PDF)

**Pronto quando:** o canvas está no repositório.
```

### Título: `[ENT-3] Dados de demonstração`
**Labels:** `E8 · Entregáveis` `banco` `mvp` · **Milestone:** Semana 4

**Descrição:**
```markdown
Dados realistas para desenvolver os painéis e gravar a demo.

**O que fazer**
- [ ] Script que cria a Dra. Helena, Dona Maria, Carla e mais 4 pacientes
- [ ] 14 dias de histórico de doses com alguns esquecimentos
- [ ] Um comando para apagar e recriar tudo

**Pronto quando:** um comando recria o ambiente de demonstração do zero.

**Depende de:** SET-6
```

### Título: `[ENT-4] Teste de ponta a ponta do fluxo`
**Labels:** `E8 · Entregáveis` `back-end` `mvp` · **Milestone:** Semana 5

**Descrição:**
```markdown
Garantir que a demo funciona em celular de verdade.

**O que fazer**
- [ ] Escrever o roteiro: cadastrar → receber lembrete → não responder → cuidador recebe alerta → relatório atualizado
- [ ] Rodar o roteiro e anotar os problemas
- [ ] Corrigir e rodar de novo

**Pronto quando:** o roteiro passa duas vezes seguidas sem ajuste manual.

**Depende de:** ALR-2, DOC-3
```

### Título: `[ENT-5] Vídeo-pitch de 3 minutos`
**Labels:** `E8 · Entregáveis` `docs` `mvp` · **Milestone:** Semana 6

**Descrição:**
```markdown
Entregável final do SuperNova.

**O que fazer**
- [ ] Roteiro: problema, solução, demo, modelo de negócio
- [ ] Gravar a demo do fluxo
- [ ] Editar e revisar o tempo (até 3 min)

**Pronto quando:** o vídeo está enviado na plataforma do SuperNova.

**Depende de:** ENT-4
```

---

## Resumo por semana

| Semana | Tarefas |
|---|---|
| 1 | SET-1 a SET-6, WPP-1, ENT-1 |
| 2 | AUTH-1 a AUTH-4, ENT-2 |
| 3 | AUTH-5, MED-1 a MED-4, WPP-2, WPP-3 |
| 4 | MED-5, MED-6, WPP-4 a WPP-7, ALR-1, DOC-1 a DOC-3, DOC-5, CAR-1, ENT-3 |
| 5 | ALR-2 a ALR-4, DOC-4, DOC-6, CAR-2, CAR-3, ENT-4 |
| 6 | ALR-5, EXT-1, EXT-2, ENT-5, ajustes |
