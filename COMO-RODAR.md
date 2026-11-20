# Como rodar cada parte do Cuidar+

O repositório tem uma pasta para cada etapa do projeto. Este arquivo explica o que cada uma é e como
abrir ou rodar cada uma. O que já foi feito e o que falta está em [`docs/ETAPAS.md`](docs/ETAPAS.md).

| Pasta | O que é | Como abrir | Precisa instalar |
|---|---|---|---|
| [`pesquisa/`](#pesquisa) | Painel com as respostas do formulário | Dois cliques no `index.html` | Nada (Python só para atualizar) |
| [`prototipo/`](#protótipo) | Desenho navegável das telas | Dois cliques no `index.html` | Nada |
| [`MVP/`](#mvp) | O app de verdade, em Flutter | `flutter run` | Flutter |
| [`landing-page/`](#landing-page) | Página de apresentação | Dois cliques no `index.html` | Nada |
| [`docs/`](#docs) | Guia das etapas, backlog e documento | Abrir os arquivos | Nada |

Os comandos abaixo são para o terminal do VS Code (PowerShell, no Windows), sempre a partir da raiz do
repositório.

---

## Pesquisa

**O que é:** um painel com gráficos das respostas do formulário (Google Forms) e das anotações das
entrevistas com médicos. Serve para justificar as decisões do projeto e entra no entregável de
pesquisa (`ENT-1`). O painel nunca mostra nome nem contato de quem respondeu.

**Como abrir:** dê dois cliques em `pesquisa/index.html`. Ele abre no navegador com os dados que já
estão salvos e funciona sem instalar nada.

**Como atualizar com respostas novas:**

1. No Google Forms, exporte as respostas para o Sheets e baixe como Excel (**Arquivo → Fazer download
   → Microsoft Excel**).
2. Salve como `pesquisa/dados/Cuidar_respostas.xlsx`. A planilha não vai para o GitHub, porque tem
   nomes e contatos. Cada pessoa guarda a sua cópia no próprio computador.
3. Se tiver observações novas de entrevistas, edite `pesquisa/dados/entrevistas.txt`.
4. Rode o script, que precisa do Python instalado:
   ```powershell
   cd pesquisa
   pip install openpyxl     # só na primeira vez
   python gerar_dados.py
   ```
5. Atualize o `index.html` no navegador.

Mais detalhes em [`pesquisa/LEIA-ME.txt`](pesquisa/LEIA-ME.txt).

---

## Protótipo

**O que é:** o desenho das telas do idoso, do cuidador e do médico, feito em HTML. Dá para clicar,
trocar de perfil e simular o lembrete e o alerta, mas não é o app: não instala no celular e não
guarda nada. Foi feito antes do MVP para validar a ideia e continua salvo como referência.

**Como abrir:** dê dois cliques em `prototipo/index.html`.

Com internet, a página usa as fontes do projeto. Sem internet, usa a fonte do sistema e continua
funcionando.

---

## MVP

**O que é:** o app do Cuidar+ em Flutter. Tem todas as telas dos três perfis (idoso, cuidador e
médico) e as regras de lembrete e alerta funcionando. Por enquanto os dados ficam só na memória e
as contas são de demonstração. Banco, login real e notificações no celular entram nas próximas
semanas.

### Antes da primeira vez

1. Instale o Flutter: <https://docs.flutter.dev/get-started/install/windows>.
2. Confira se está tudo certo:
   ```powershell
   flutter doctor
   ```
   Para rodar no navegador, basta o Chrome ou o Edge. Os avisos de Android ou Visual Studio só
   importam se for rodar no celular ou como programa do Windows.
3. Baixe os pacotes do projeto:
   ```powershell
   cd MVP
   flutter pub get
   ```

### Rodar

```powershell
cd MVP
flutter run -d chrome
```

Também dá para usar `-d edge`, ou um celular Android ligado no cabo com a depuração USB ativada (o
`flutter devices` mostra os aparelhos encontrados).

Com o app aberto, no terminal:
- **`r`** recarrega o app com as mudanças do código (mantém onde você está);
- **`R`** reinicia o app do zero;
- **`q`** fecha.

### Contas de demonstração

Na tela de login há botões para entrar direto. Todas as contas usam a senha `123456`.

| Conta | Perfil | O que mostra |
|---|---|---|
| `maria@cuidar.app` | Idosa que usa o app | Chat de lembretes com a Losartana das 08:00 esperando resposta |
| `carla@cuidar.app` | Cuidadora | Acompanha a Dona Maria (com app) e o Seu Antônio (sem app) |
| `helena@cuidar.app` | Médica | Pacientes por exceção e relatórios de adesão |

No menu da conta (canto superior direito):
- **Passar 15 minutos:** avança o relógio da demonstração, que começa às 08:05;
- **Recomeçar demonstração:** volta tudo ao início.

**Roteiro para testar o fluxo completo:** entre como Dona Maria e toque 2 vezes em "Me lembra em
15 min". Saia, entre como Carla e veja o alerta. Saia, entre como Dra. Helena e veja a Dona Maria
em "Precisam de atenção".

### Testes

```powershell
cd MVP
flutter test        # roda os 9 testes; o esperado é "All tests passed!"
flutter analyze     # procura erros no código sem abrir o app
```

Os testes ficam em [`MVP/test/widget_test.dart`](MVP/test/widget_test.dart):
- **fumaça:** o app abre e o login funciona;
- **layout:** todas as telas cabem num celular pequeno com a letra em 100% e em 200%;
- **regras:** alertas, adiamentos, idoso sem app e convite.

Rode os dois antes de abrir um pull request. Para rodar só parte dos testes:

```powershell
flutter test --plain-name "fumaça"
flutter test --plain-name "Regras de escalada"
```

Os testes não mostram o visual. Antes de entregar, abra o app e confira os fluxos com a letra no
máximo (botão **A+**).

### Se der erro

| Erro | O que fazer |
|---|---|
| `flutter` não é reconhecido | O Flutter não está no PATH. Reabra o VS Code depois de instalar, ou siga o passo de PATH do guia de instalação |
| Erro de pacote ou `pub get failed` | `flutter clean` e depois `flutter pub get` |
| Erro estranho depois de trocar de branch | `flutter clean`, `flutter pub get` e rode de novo |
| Chrome não aparece em `flutter devices` | Rode `flutter config --enable-web` e reabra o terminal |

Mais detalhes do app (telas, estrutura de pastas e acessibilidade) em [`MVP/README.md`](MVP/README.md).

---

## Landing page

**O que é:** a página de apresentação do Cuidar+: o problema, a solução, os perfis e como funciona.
Pode servir para o pitch e para divulgar o projeto.

**Como abrir:** dê dois cliques em `landing-page/index.html`. Como o protótipo, usa as fontes do
projeto com internet e a fonte do sistema sem.

---

## Docs

**O que é:** a documentação do projeto. Não tem nada para rodar.

| Arquivo | O que é |
|---|---|
| [`docs/ETAPAS.md`](docs/ETAPAS.md) | O que é protótipo, MVP e produto final; o que já foi feito e o que falta |
| [`docs/BACKLOG.md`](docs/BACKLOG.md) | Todas as tarefas para o GitHub Projects, com labels e semana |
| [`docs/Cuidar_Documento_do_Projeto_v2.pdf`](docs/Cuidar_Documento_do_Projeto_v2.pdf) | Documento do projeto, versão atual. É a referência |
| [`docs/antigo/`](docs/antigo/) | Documento da v1, quando a ideia usava WhatsApp. Só histórico, não seguir |
