# Validação do CuidarMais

Testes da etapa de MVP do SuperNova (entregável `ENT-5`). Tudo grátis.

| Teste | Pergunta | Arquivo |
|---|---|---|
| 1. Teste fumaça | Cuidadores querem o CuidarMais? | [`1-teste-fumaca.md`](1-teste-fumaca.md) |
| 2. Teste de uso (Mágico de Oz) | O idoso e o cuidador conseguem usar sozinhos? | [`2-teste-de-uso.md`](2-teste-de-uso.md) |

**Privacidade:** nestes arquivos, use só "Participante 1, 2, 3". Nomes, emails e telefones ficam
no Firebase ou com vocês, nunca no Git.

## Configurar uma vez (cerca de 10 minutos, sem cartão)

Quem tem acesso ao projeto `cuidarmais-eee0c` no [console do Firebase](https://console.firebase.google.com)
faz isto. O plano continua o **Spark (grátis)**: não aceite mudar para o Blaze.

**1. Ligar o banco que guarda os emails (Firestore)**
1. No console, abra **Firestore Database** e clique em **Criar banco de dados**.
2. Escolha a região `southamerica-east1 (São Paulo)` e o **modo de produção**.

**2. Ligar o contador de visitas (Google Analytics)**
1. No console, abra a engrenagem **Configurações do projeto** e vá em **Integrações**.
2. Em **Google Analytics**, clique em **Ativar** e crie uma conta nova, que é grátis.
3. Depois vá em **Configurações do projeto** e abra **Geral**. Clique em **Adicionar app** e escolha **Web** (`</>`).
4. Copie o `measurementId`, que começa com `G-`.
5. Cole esse valor em `landing-page/index.html`, na linha `ANALYTICS_ID: ''`.

**3. Publicar** (no PC onde o Firebase CLI está instalado)
```bash
firebase deploy --only firestore:rules,hosting:landing
```
Esse comando sobe as regras de segurança ([`firestore.rules`](../firestore.rules)) e a landing nova.

**4. Conferir:** abra a landing, preencha o "Quero testar" com o seu email e veja se o registro
aparece em **Firestore Database**, na coleção `interessados`.

## Onde ver os números

| O quê | Onde |
|---|---|
| Visitas | Console do Firebase, na tela **Analytics**, em **Dashboard** (aparece em até 24 h). Para ver na hora, use **Tempo real** no [Google Analytics](https://analytics.google.com) |
| Cliques em "Testar o app" | No Analytics, abra **Eventos** e procure `abrir_app` |
| Emails deixados | No Firestore, na coleção `interessados`: o total de documentos e o perfil de cada um. O evento `generate_lead` no Analytics também conta |
| De onde veio cada pessoa | Campo `origem` do Firestore (veja o próximo item) |

## Saber de qual grupo veio cada pessoa

Divulgue um link diferente em cada lugar, mudando só o final:

```
https://cuidarmais-eee0c.web.app/?utm_source=whatsapp-familia
https://cuidarmais-eee0c.web.app/?utm_source=instagram
https://cuidarmais-eee0c.web.app/?utm_source=grupo-cuidadores
```

O que vem depois de `utm_source=` fica salvo no campo `origem` de cada email.

## Resultado final

Preencha ao terminar os dois testes. Isto vira slide do pitch (`ENT-6`).

| Pergunta | Meta | Resultado | Passou? |
|---|---|---|---|
| Visitantes que deixaram o email | ≥ 10% | | |
| Tarefas feitas sem ajuda no teste de uso | ≥ 80% | | |
| Cuidadores que disseram que usariam | ≥ 2 de 3 | | |

**O que vamos mudar no app por causa dos testes:**
-
