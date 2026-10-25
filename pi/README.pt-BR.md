# Kit do Raspberry Pi

[English](README.md) | **Português (Brasil)**

Tudo o que é preciso para transformar um Raspberry Pi 5 na máquina de referência: Project OutFox, este tema com todas as suas artes, a configuração de tela e de inicialização, as preferências e o mapeamento do tapete. As músicas não fazem parte.

## Passos

1. Grave o **Raspberry Pi OS (64-bit) com área de trabalho** no cartão pelo Raspberry Pi Imager (testado com a versão baseada no Debian 13 "trixie"), ligue o Pi e conecte-o à internet. Qualquer nome de usuário serve, e o `git` já vem no sistema.
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

5. Opcional, mais noteskins: o download do XSanity traz 11 noteskins de Pump e o OutFox tem 6 próprias. O Pi de referência tem 61, de uma coleção pessoal guardada no `noteskins-xsanity.zip`, que não é publicada (as noteskins são arte da Andamiro). Qualquer conjunto de noteskins de Pump se instala do mesmo jeito, a partir de uma pasta ou zip com uma pasta `pump` dentro, e recebe as mesmas correções das do XSanity:

   ```bash
   bash ~/.project-outfox/Themes/Infinitesimal/pi/assets.sh --noteskins ~/noteskins.zip
   ```

6. Reinicie. O Pi entra na área de trabalho e o jogo abre sozinho, em 60 Hz em qualquer tela conectada. Depois de sair do jogo, o ícone **Pump It Up (OutFox)** na área de trabalho abre de novo.
7. Se o seu tapete não for como o de referência (um adaptador USB que mostra os dois tapetes como um joystick só, jogador 1 nos botões 1 a 5 e jogador 2 nos 6 a 10; o `config/outfox/Keymaps.ini` tem o botão de cada painel), mapeie em INPUT OPTIONS, nas opções do OutFox. Para abri-las na tela inicial, pise vermelho esquerdo, vermelho direito, azul esquerdo, azul direito, duas vezes. Até o tapete funcionar dá para usar o teclado: o jogador 1 fica em Q, E, S, Z, C (cima-esquerda, cima-direita, centro, baixo-esquerda, baixo-direita).

Os dois scripts podem ser rodados de novo a qualquer momento: eles pulam o que já está pronto e guardam como `*.bak-hexagono` qualquer arquivo que substituírem.

## O que o `setup.sh` faz

| Etapa | Resultado |
|---|---|
| Sistema (`sudo`) | login automático na área de trabalho, tela sem apagar; pacotes: git, curl, ffmpeg, Python com Pillow e numpy, nodejs, grim, wlr-randr, kanshi, fontes da Microsoft (opcional) |
| Project OutFox | 0.5.0-pre043 para Raspberry Pi, em `~/ProjectOutFox` |
| Tela | `~/.local/bin/display-60hz` escolhe o melhor modo de 60 Hz até cerca de 1080p em qualquer tela (TVs costumam preferir 4K a 30 Hz, o que prende o jogo em 30 FPS); roda no login e pelo kanshi sempre que uma tela é conectada. `~/.local/bin/display-watch` confere as telas a cada 2 s para pegar o que o kanshi perde, como uma TV desligada no boot que é ligada depois (ela pula para o 4K a 30 Hz preferido): volta para 60 Hz e reinicia o jogo se ele foi aberto noutra tela ou se a tela sumiu nesse meio-tempo (ligar a TV pode derrubar a saída HDMI por um instante) |
| Inicialização | `~/.config/labwc/autostart` inicia o display-watch e abre o jogo por `~/.local/bin/outfox-run`, que espera uma tela de verdade (com a TV desligada, o HDMI informa uma tela genérica de 1024x768) e abre o jogo de novo 10 s depois de um crash; para parar, `~/.local/bin/outfox-stop`. A área de trabalho ganha um ícone Pump It Up (OutFox), que também usa o outfox-run |
| Cursor do mouse | escondido enquanto a janela do jogo está aberta (`~/.config/labwc/rc.xml`) |
| Preferências do OutFox | modo pump, este tema, 1280x720 em tela cheia com vsync, cache de imagens e texturas que mantêm os menus em 60 FPS (`config/outfox/Preferences.ini` lista cada chave). O `merge_prefs.py` muda só essas chaves, onde o OutFox as guarda, inclusive a seção `[Game-pump]`: é de lá que o OutFox tira o tema do jogo atual ao abrir, então sem ela uma instalação nova abre o tema padrão do OutFox |
| Opções do tema | `config/outfox/OutFoxPrefs.ini`: charts UCS, quest e escondidos ocultos, bola de dificuldade grande, lista de dificuldades que dá a volta nas pontas etc. |
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
| `~/.project-outfox/NoteSkins/pump` | as noteskins Pump do XSanity: o download traz 11; o Pi de referência tem 61, de uma coleção pessoal guardada no `noteskins-xsanity.zip`, que não é publicada (guarde-a junto com as músicas; `--noteskins CAMINHO` instala esse ou qualquer outro conjunto); o skin `default` do XSanity vira `xs_default`; explosões que só apareciam durante um combo aparecem também na primeira nota e depois de um erro |
| `Graphics/Phoenix/Avatars` | os 165 ícones de jogador do Phoenix, do piugame.com (`PIU 001.png` ..), oferecidos em EDIT PHOTO na seleção de perfil, pelo `assets/avatars.py` |
| `Thumbs` | feitas a partir dos banners e fundos das músicas pelo `tools/make_thumbs.py`, quando as músicas já estão instaladas |

Opções: `--no-video`, `--no-xsanity`, `--xsanity CAMINHO`, `--noteskins CAMINHO`, `--font TTF`. Se um download falha, o script continua e lista o que ficou faltando; o tema usa os próprios gráficos ou texto no lugar do que estiver ausente.

## Músicas

Não incluídas. O tema agrupa as músicas pela pasta de cada versão, então use nomes `NN - NOME` na ordem de lançamento: `01 - 1ST~3RD`, `02 - S.E.~EXTRA`, ... `16 - PHOENIX`, `17 - PHOENIX 2`. Um jogo novo abre a seleção numa música aleatória da última. Os vídeos de fundo (BGAs) ficam dentro da pasta de cada música, como de costume no OutFox.

## Comparado com o Pi de referência

Um Pi montado com estes passos abre o mesmo jogo: o tema com as artes, o vídeo de abertura, a animação de estouro e os ícones de jogador, a configuração de tela e de inicialização, as preferências e os perfis reservados. O que ele não traz:

- **Músicas e seus BGAs**: as suas, organizadas como em [Músicas](#músicas).
- **Noteskins**: 11 do XSanity mais as 6 do OutFox, no lugar das 61 do Pi de referência, a menos que você instale um conjunto seu (passo 5).
- **Perfis, notas e as opções de cada jogador**: dados pessoais em `~/.project-outfox/Save`. Para levá-los a outro Pi, copie `Save/LocalProfiles` e `Save/MachineProfile` com o jogo fechado.
- **Cartões e nomes de categoria**: em Verdana só quando a licença das fontes da Microsoft é aceita; senão, em DejaVu Sans.
- **Sincronia do áudio**: medida no Pi de referência (veja [Calibração](#calibração)).

As artes vêm do GitHub (phyrebird), do YouTube, do xsanity.net e do piugame.com: quando um deles está fora do ar, o `assets.sh` lista o que faltou e pode ser rodado de novo depois.

## Verificações

- `python3 pi/tests/test_<nome>.py`, um por parte: `display60` (escolha do modo de 60 Hz), `display_watch` (vigia de telas), `merge_prefs` (preferências), `title` (tempos do vídeo de abertura), `noteskins` (correção das explosões), `avatars` (ícones de jogador).
- FPS: com `ShowStats=1` no `Preferences.ini`, o OutFox grava uma linha por segundo com `:Video, , <fps> FPS` em `~/.project-outfox/Logs/ProjectOutfox.MainLog.*.log`.
- `~/.cache/display-60hz.log` e `~/.cache/outfox-run.log` mostram o que os scripts de tela e de inicialização fizeram.

## Calibração

O `GlobalOffsetSeconds` em `config/outfox/Preferences.ini` foi medido no Pi de referência. Com outro hardware de áudio, calibre de novo nas opções do OutFox.
