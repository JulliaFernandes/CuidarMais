/// Configurações do app ligado ao Firebase.
library;

/// Chave pública de Web Push do projeto Firebase (Configurações do projeto >
/// Cloud Messaging > Certificados de push da Web > "Par de chaves").
/// Sem ela, a notificação no navegador não funciona; no Android funciona
/// mesmo assim. Não é segredo: pode ficar no código.
const kWebPushKey = 'BNPavhs3LRM9NhOvN90cSM3TZq4S59uDqTgpd7Ca2ove7Iz5eELDvWhivEco4pnv2chW104xCYndjkCd3vRM77Q';

/// Endereço do app publicado, usado no link das notificações.
const kAppUrl = 'https://cuidarmais-app.web.app';
