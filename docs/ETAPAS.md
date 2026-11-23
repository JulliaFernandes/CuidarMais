# Etapas do CuidarMais: o que é cada pasta e o que falta

Este guia mostra o que cada pasta guarda, o que já está feito, o que precisa ficar pronto nas 6
semanas e o que fica para depois. Quando bater a dúvida "isso precisa agora?", a resposta está aqui.

## O que é cada pasta

| Pasta | O que é | Situação |
|---|---|---|
| [`pesquisa/`](../pesquisa/) | Painel com as respostas do formulário e as anotações das entrevistas com médicos | ✅ atualize quando chegarem respostas novas |
| [`prototipo/`](../prototipo/) | **Protótipo:** desenho navegável das telas, em HTML. Mostra como o app vai ser, mas não é o app | ✅ pronto, fica guardado como referência |
| [`MVP/`](../MVP/) | **MVP:** o app de verdade, em Flutter | 🔨 telas e regras prontas; falta banco, login real e notificações |
| [`landing-page/`](../landing-page/) | Página de apresentação do CuidarMais | ✅ pronta, pode servir para o pitch |
| [`validacao/`](../validacao/LEIA-ME.md) | Teste fumaça da landing e teste de uso do app, com os resultados | 🔨 configurar o Firebase e aplicar |
| [`identidade-visual/`](../identidade-visual/LEIA-ME.md) | Logo, símbolo, ícone do app e cores da marca | ✅ use nos slides e no pitch |
| [`docs/`](./) | Este guia, o [backlog](BACKLOG.md) e o [documento do projeto v2](Cuidar_Documento_do_Projeto_v2.pdf) | ✅ o documento v2 é a referência |
| [`docs/antigo/`](antigo/) | Documento da v1, quando a ideia ainda usava WhatsApp | 📎 só histórico, não seguir |

A ordem das pastas é a ordem em que as coisas foram feitas: pesquisa → protótipo → MVP. A landing
page é a apresentação do projeto.

## Protótipo e MVP: qual a diferença

| | Protótipo (`prototipo/`) | MVP (`MVP/`) |
|---|---|---|
| **O que é** | Desenho das telas em HTML | O app em Flutter |
| **Para quê** | Mostrar a ideia e validar as telas | Uma família real usar no dia a dia |
| **Instala no celular?** | Não, abre no navegador | Sim (Android) |
| **Dados** | Simulados | Hoje simulados; no fim, banco PostgreSQL |
| **Login** | Não tem | Hoje contas de demonstração; no fim, cadastro e login reais |
| **Lembrete** | Simulado na tela | Hoje no chat; no fim, notificação no celular |

## MVP: o que já está pronto

Pasta [`MVP/`](../MVP/). Como rodar: [`MVP/README.md`](../MVP/README.md).

- [x] Boas-vindas, login, criar conta em 3 passos (com LGPD) e recuperar senha
- [x] **Idoso:** chat de lembretes (Tomei, Me lembra em 15 min até 2 vezes), lista do dia, remédios e família
- [x] **Cuidador:** início com alertas, histórico de alertas, ficha do idoso com e sem app e adicionar idoso
- [x] **Médico:** pacientes por exceção, relatório de adesão, cadastrar remédio e adicionar paciente
- [x] Regras: alerta após 2 adiamentos ou sem resposta, aviso a cada 15 min do idoso sem app, convite por código
- [x] Acessibilidade para idosos: letra até 200%, botões grandes, status com ícone e texto
- [x] 9 testes automáticos (fumaça, layout com letra grande e regras)

Por enquanto os dados ficam só na memória e as contas são de demonstração. É isso que a próxima
parte resolve.

## MVP: o que falta para as 6 semanas

Tudo isto está no [backlog](BACKLOG.md) com a label `mvp`.

**Banco e API (Python + PostgreSQL, ainda não existe)**
- [ ] Criar a API (`SET-3`) e o modelo de dados (`SET-6`)
- [ ] Cadastro e login reais (`AUTH-1`), convite (`AUTH-4`), idoso sem app (`AUTH-6`), médico e paciente (`AUTH-7`), LGPD (`AUTH-8`)
- [ ] Medicamentos com origem e geração das doses (`MED-1`, `MED-2`)
- [ ] Confirmação "Tomei" (`LEM-3`), agendador e regras de alerta (`ESC-1`, `ESC-2`)
- [ ] Status do dia e dos 7 dias para o cuidador (`CUI-4`), cálculo de adesão (`DOC-2`, `DOC-4`)

**Notificações**
- [ ] Configurar o Firebase Cloud Messaging (`SET-5`)
- [ ] Lembrete agendado no celular (`LEM-1`)
- [ ] Alerta ao cuidador pelo push (`ESC-3`, `ESC-4`, `ESC-5`)

**App: as telas já existem em `MVP/`, falta ligar à API**
- [ ] Login e cadastro (`AUTH-2`), convite (`AUTH-5`)
- [ ] Formulário de remédio (`MED-3`)
- [ ] Chat de lembretes e "Me lembra em 15 min" (`LEM-2`, `LEM-4`), lista do dia (`LEM-5`)
- [ ] Telas do cuidador (`CUI-1`, `CUI-2`, `CUI-3`)

**Site do médico (Next.js, ainda não existe)**
- [ ] Criar o projeto (`SET-4`) e o login (`AUTH-3`)
- [ ] Refazer na web as telas que hoje estão no app: painel por exceção e relatório (`DOC-1`, `DOC-3`, `DOC-5`), formulário de remédio (`MED-4`)

**Entregáveis do SuperNova**
- [ ] Pesquisa (`ENT-1`), Business Model Canvas (`ENT-3`), testes com usuários (`ENT-5`), vídeo-pitch (`ENT-6`)

> **E o que o SuperNova pede?** A lista de entregáveis fala em "protótipo (MVP) com o fluxo
> completo". O app em `MVP/` já mostra esse fluxo com dados de demonstração. O plano de vocês vai
> além e liga o app a um banco real nas semanas 3 a 5. Se o tempo apertar, o que já existe garante
> a demonstração.

## Produto final: depois da jornada

Label `depois` no backlog. **Não fazer agora.**

- Fila de revisão do médico para remédios cadastrados pela família ou pelo paciente (`DEP-1`)
- Cadastro por foto da receita (`DEP-2`)
- Detecção de padrões de esquecimento (`DEP-3`)
- Alergias e controle de estoque (`DEP-4`)
- Diferenciar "sem resposta" de "celular sem internet" (`DEP-5`)
- Versão para iPhone (`DEP-6`; exige conta paga da Apple e um Mac)
- WhatsApp ou SMS para quem não tem smartphone (tem custo por mensagem)

## Testes: onde ficam e quando rodar

Os testes ficam em [`MVP/test/widget_test.dart`](../MVP/test/widget_test.dart). Conforme o banco e as
notificações entrarem, entram testes novos, como "a conta continua lá depois de fechar o app".

```bash
cd MVP
flutter test        # todos os testes
flutter analyze     # procura erros no código sem abrir o app
```

Rode os dois antes de abrir um pull request. Os testes automáticos não mostram o visual, então
abra o app no navegador e confira os fluxos com a letra no máximo (botão A+).
