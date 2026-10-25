# Kit do Raspberry Pi

[English](README.md) | **Português (Brasil)**

Tudo o que é preciso para transformar um Raspberry Pi 5 na máquina de referência: Project OutFox, este tema com todas as suas artes, a configuração de tela e de inicialização, as preferências e o mapeamento do tapete. As músicas não fazem parte.

## Passos

1. Grave o **Raspberry Pi OS (64-bit) com área de trabalho** no cartão (Raspberry Pi Imager), ligue o Pi e conecte-o à internet.
2. Clone o tema na pasta que o OutFox lê:

   ```bash
   git clone https://github.com/kalinathalie/hexagono.git ~/.project-outfox/Themes/Infinitesimal
   ```

3. Rode a instalação (cerca de 20 minutos, a maior parte downloads e o vídeo de abertura):

   ```bash
   bash ~/.project-outfox/Themes/Infinitesimal/pi/setup.sh
   ```

   No meio, o instalador das fontes da Microsoft mostra a licença delas. Aceitando, os cartões de canal gerados ficam com a fonte original (Verdana); recusando também funciona, e os cartões usam a DejaVu Sans.
4. Copie as pastas de músicas para `~/.project-outfox/Songs`, uma pasta por versão, com nomes como `17 - PHOENIX 2` (veja [Músicas](#músicas)), e gere as miniaturas da roda:

   ```bash
   cd ~/.project-outfox/Themes/Infinitesimal && python3 tools/make_thumbs.py
   ```

5. Opcional: o download do XSanity traz 11 noteskins. Para instalar o conjunto completo do Pi de referência (61), copie o `noteskins-xsanity.zip` para o Pi e rode:

   ```bash
   bash ~/.project-outfox/Themes/Infinitesimal/pi/assets.sh --noteskins ~/noteskins-xsanity.zip
   ```

6. Reinicie. O Pi entra na área de trabalho e o jogo abre sozinho, em 60 Hz em qualquer tela conectada.

Os dois scripts podem ser rodados de novo a qualquer momento: eles pulam o que já está pronto e guardam como `*.bak-hexagono` qualquer arquivo que substituírem.

## O que o `setup.sh` faz

| Etapa | Resultado |
|---|---|
| Sistema (`sudo`) | login automático na área de trabalho, tela sem apagar; pacotes: git, curl, ffmpeg, Python com Pillow e numpy, nodejs, grim, wlr-randr, kanshi, fontes da Microsoft (opcional) |
| Project OutFox | 0.5.0-pre043 para Raspberry Pi, em `~/ProjectOutFox` |
| Tela | `~/.local/bin/display-60hz` escolhe o melhor modo de 60 Hz até cerca de 1080p em qualquer tela (TVs costumam preferir 4K a 30 Hz, o que prende o jogo em 30 FPS); roda no login e pelo kanshi sempre que uma tela é conectada. `~/.local/bin/display-watch` confere as telas a cada 2 s para pegar o que o kanshi perde, como uma TV desligada no boot que é ligada depois (ela pula para o 4K a 30 Hz preferido): volta para 60 Hz e reinicia o jogo se ele foi aberto noutra tela ou se a tela sumiu nesse meio-tempo (ligar a TV pode derrubar a saída HDMI por um instante) |
| Inicialização | `~/.config/labwc/autostart` inicia o display-watch e abre o jogo por `~/.local/bin/outfox-run`, que espera uma tela de verdade (com a TV desligada, o HDMI informa uma tela genérica de 1024x768) e abre o jogo de novo 10 s depois de um crash; para parar, `~/.local/bin/outfox-stop` |
| Cursor do mouse | escondido enquanto a janela do jogo está aberta (`~/.config/labwc/rc.xml`) |
| Preferências do OutFox | modo pump, este tema, 1280x720 em tela cheia com vsync, cache de imagens e texturas que mantêm os menus em 60 FPS (`config/outfox/Preferences.ini` lista cada chave) |
| Opções do tema | `config/outfox/OutFoxPrefs.ini`: charts UCS, quest e escondidos ocultos, bola de dificuldade grande etc. |
| Mapeamento do tapete | `config/outfox/Keymaps.ini`: jogador 1 nos botões 1 a 5 do joystick e nas teclas Q E S Z C, jogador 2 nos botões 6 a 10 e no teclado numérico. Outro tapete pode precisar ser mapeado de novo nas opções do OutFox |
| Perfis reservados | 6 perfis locais reservados que o CREATE PROFILE da tela de perfis renomeia (o Lua do OutFox não consegue criar perfis) |
| Artes do tema | roda o `assets.sh` (pule com `--no-assets`) |

Opções: `--no-assets` pula as artes, `--no-system` pula as etapas que precisam de `sudo`.

## As artes do tema: `assets.sh`

As artes pertencem à Andamiro e aos autores do phyrebird e do XSanity, então o repositório guarda a receita em vez dos arquivos. O `assets.sh` baixa cada uma da sua origem e gera o resto, nas pastas ignoradas pelo git que o tema lê:

| Pasta | Origem |
|---|---|
| `Graphics/Phoenix/Channels` | cartões de canal do [phyrebird](https://github.com/rayden-61/phyrebird), reduzidos para 320 px; Double 1-4 e 26-28, Single 24-26, Half-Double e cartões de categoria feitos pelo `tools/make_phoenix_cards.py` |
| `Graphics/Phoenix/CommandWindow` | a command window do phyrebird; os nomes nítidos das categorias feitos pelo `tools/make_phoenix_labels.py` |
| `Graphics/Phoenix` | bolas de dificuldade, MY BEST, READY, cursores e setas do phyrebird; `RecordGrades` também |
| `Graphics/Phoenix/Logo` | o logo do Phoenix 2, recortado pelo `tools/make_phoenix_logo.py` |
| `Graphics/Phoenix/Title` | o vídeo de abertura do Phoenix 2 no YouTube, cortado onde o loop de espera se repete e convertido para a faixa completa de cor, pelo `assets/title.py` |
| `Graphics/Phoenix/StageBreak` | a animação "HEY! WHY DON'T YOU JUST GET UP AND DANCE MAN?" do Phoenix 2, mostrada quando um jogador estoura, do YouTube, pelo `assets/stagebreak.py` |
| `Graphics/XSanity`, `Graphics/XSCommandWindow` | do XSanity 0.96.0, baixado de [xsanity.net](https://xsanity.net/downloads.php) (`--xsanity CAMINHO` usa uma instalação ou zip que você já tem; versões mais novas mudaram as artes e trazem menos noteskins) |
| `~/.project-outfox/NoteSkins/pump` | as noteskins Pump do XSanity: o download traz 11; o Pi de referência tem 61, guardadas no `noteskins-xsanity.zip` (guarde-o junto com as músicas e passe com `--noteskins CAMINHO`); o skin `default` do XSanity vira `xs_default` |
| `Thumbs` | feitas a partir dos banners e fundos das músicas pelo `tools/make_thumbs.py`, quando as músicas já estão instaladas |

Opções: `--no-video`, `--no-xsanity`, `--xsanity CAMINHO`, `--noteskins CAMINHO`, `--font TTF`. Se um download falha, o script continua e lista o que ficou faltando; o tema usa os próprios gráficos ou texto no lugar do que estiver ausente.

## Músicas

Não incluídas. O tema agrupa as músicas pela pasta de cada versão, então use nomes `NN - NOME` na ordem de lançamento: `01 - 1ST~3RD`, `02 - S.E.~EXTRA`, ... `16 - PHOENIX`, `17 - PHOENIX 2`. Um jogo novo abre a seleção numa música aleatória da última. Os vídeos de fundo (BGAs) ficam dentro da pasta de cada música, como de costume no OutFox.

## Verificações

- `python3 pi/tests/test_display60.py` testa a escolha do modo de 60 Hz, `python3 pi/tests/test_display_watch.py` o vigia de telas.
- FPS: com `ShowStats=1` no `Preferences.ini`, o OutFox grava uma linha por segundo com `:Video, , <fps> FPS` em `~/.project-outfox/Logs/ProjectOutfox.MainLog.*.log`.
- `~/.cache/display-60hz.log` e `~/.cache/outfox-run.log` mostram o que os scripts de tela e de inicialização fizeram.

## Calibração

O `GlobalOffsetSeconds` em `config/outfox/Preferences.ini` foi medido no Pi de referência. Com outro hardware de áudio, calibre de novo nas opções do OutFox.
