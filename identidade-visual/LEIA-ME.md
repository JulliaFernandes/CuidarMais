# Identidade visual do CuidarMais

| Arquivo | O que é | Onde usar |
|---|---|---|
| [`logo.png`](logo.png) | Logo completa (símbolo + nome), fundo transparente | Slides, pitch, documentos, cabeçalho de site. **Só sobre fundo claro** (o "Cuidar" é verde-escuro) |
| [`simbolo.png`](simbolo.png) | Só a cruz com o coração, fundo transparente | Dentro do app, ao lado do nome escrito, e em espaços pequenos |
| [`icone-app.png`](icone-app.png) | Ícone do app (quadrado verde arredondado) | Ícone do celular, aba do navegador, redes sociais |
| [`originais/`](originais/) | As imagens como foram criadas (1920×1080, fundo branco) | Para refazer as versões acima |

## Cores

| Cor | Hex | RGB | Uso |
|---|---|---|---|
| Verde da marca | `#0E6B66` | 14, 107, 102 | Cor principal, idoso, "Tomei" |
| Verde escuro | `#0B4F4B` | 11, 79, 75 | Títulos, cabeçalho, barra do topo |
| Coral da logo | `#E4533F` | 228, 83, 63 | Só na logo e em ilustrações grandes, nunca em texto pequeno |
| Fundo | `#FFF8EF` | 255, 248, 239 | Fundo das telas |
| Texto | `#1C2B29` | 28, 43, 41 | Texto principal |

As outras cores do app (cuidador, médico, atenção e alerta) estão em
[`MVP/lib/core/theme/app_colors.dart`](../MVP/lib/core/theme/app_colors.dart).

## Onde a marca já está aplicada

- **App:** símbolo na tela de boas-vindas e na barra do topo (`MVP/assets/marca/simbolo.png`).
- **Celular Android:** ícone da tela inicial, em todos os tamanhos (`MVP/android/app/src/main/res/mipmap-*`).
- **App no navegador:** ícone da aba, ícone do atalho e cor da barra (`MVP/web/`).
- **Landing page:** símbolo no topo e no rodapé, e ícone da aba (embutidos em `landing-page/index.html`).

O protótipo (`prototipo/`) ficou com a marca antiga de propósito, para guardar como ele era.

## Se a logo mudar

Troque os arquivos de `originais/` (mesmos nomes) e peça para gerar as versões de novo. Se der, guarde
também a logo em **SVG** ou em PNG maior: os originais atuais têm o símbolo com cerca de 400 pixels, o
que basta para o app, mas fica no limite para o ícone de 512 pixels.
