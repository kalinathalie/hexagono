# Hexágono: Infinitesimal no estilo Pump It Up Phoenix

[English](README.md) | **Português (Brasil)**

Tema de Project OutFox que reproduz as telas do **Pump It Up Phoenix** (e do Phoenix 2), feito a partir do [Infinitesimal](https://github.com/Team-Infinitesimal/Infinitesimal). O Infinitesimal original é inspirado no Pump It Up Infinity. Este fork troca essa base pelo Phoenix: tela inicial, seleção de perfil, seleção de músicas, roda de grupos, janela de comandos e gameplay foram refeitas para funcionar como no fliperama, tudo pelo tapete.

Foi feito para rodar num Raspberry Pi 5 com tapete USB, travado em 60 FPS.

![Tela inicial](.github/readme/title.jpg)

## O que muda em relação ao Infinitesimal

- **Tela inicial de fliperama:** sem menu. O centro do tapete entra o jogador e um segundo toque começa; o outro lado pode entrar antes. Com o vídeo do Phoenix 2 (arte local), a abertura toca uma vez e a espera fica em loop sem emenda; o PRESS CENTER STEP aparece junto com o logo do jogo, depois do trailer. O código vermelho esquerdo, vermelho direito, azul esquerdo, azul direito, duas vezes, abre as opções.
- **Perfis pelo tapete:** na seleção de perfil, CRIAR PERFIL abre um teclado na tela: os azuis escolhem a tecla, o centro aperta e os vermelhos apagam. Azul esquerdo, azul direito, três vezes, edita o nome ou a foto de um perfil, com os avatares do OutFox e os 165 ícones de jogador do Phoenix (arte local). Com dois jogadores, os vermelhos tiram um deles, também quando o segundo entrou pela seleção de músicas.
- **Começa na versão mais nova:** cada jogo novo abre a seleção numa música aleatória da última versão (hoje o PHOENIX 2). Depois de jogar, a seleção volta para a música jogada.
- **Seleção de músicas no layout do Phoenix:** faixa de preview com o BGA no centro e cópias espelhadas nas laterais, título com artista e BPM, roda de jaquetas 4:3 com setas amarelas na música selecionada e 13 bolinhas de dificuldade com a nota recorde de cada chart. A lista de dificuldades dá a volta: esquerda no primeiro chart vai para o último e direita no último volta para o primeiro (Rolar escolha de charts nas opções do tema, ligado no kit do Pi).
- **Cronômetro no centro:** as barras de perfil do P1 e do P2 ficam dos lados do cronômetro, com nível, nome e vidas.
- **Transição ao escolher a música:** a roda sai, as bolinhas sobem e cada jogador ganha o painel MY BEST com nota, grade e placa, a bola grande do chart e o selo READY. Os vermelhos no READY tiram só o READY; de novo, voltam para a roda.
- **Roda de grupos com cartões do Phoenix:** versões do jogo, gêneros (Original, K-Pop, World Music, J-Music, Xross, pelo gênero de cada música; as versões Short Cut, Remix e Full Song ficam nos grupos próprios, como no arcade), níveis de Single (do 1 ao 26), Double (do 1 ao 28) e Half-Double, especiais e uma tela de categorias, cada uma com seu cartão.
- **Janela de comandos gráfica:** abre com o código de painéis (baixo-esquerda, baixo-direita, três vezes), também durante a escolha da dificuldade, e é navegada só pelo tapete. Na escolha da categoria, o nome dela aparece entre o da anterior e o da próxima. Tem Speed, Auto Velocity, Display, Note Skin (com prévia dos skins em volta do cursor), Judge (EJ, NJ, HJ, VJ; volta para NJ a cada jogo novo) e Judge Timing (adianta ou atrasa o julgamento de cada jogador em até 100 ms).
- **Auto Velocity no modo do PIU:** a velocidade acompanha o BPM, então as gimmicks continuam funcionando. A velocidade constante segue disponível como opção.
- **Gameplay como no fliperama:** a música só é perdida com 40 erros seguidos, com a animação "HEY! WHY DON'T YOU JUST GET UP AND DANCE MAN?" do Phoenix 2 e sem tela de notas depois; esvaziar a barra de vida não encerra a música, mas dá uma nota quebrada (cinza). Jogadas quebradas nunca viram recorde. Brilho no receptor do painel pisado com qualquer noteskin (no double, no tapete que foi pisado) e explosão em todo acerto, inclusive na primeira nota e na seguinte a um erro (o kit do Pi corrige as noteskins que só a mostravam durante um combo); notas marcadas como ocultas nos charts (gimmicks) ficam invisíveis.
- **Listas por número de jogadores:** com dois jogadores somem Double, Half-Double e Co-op; os charts de co-op ficam só no grupo Co-op.
- **Setas BACK e SHIFT nos cantos**, vindas do InfiniteWorlds.
- **Miniaturas nítidas na roda**, geradas a partir do fundo de cada música.
- **Fundo estático** no lugar do vídeo animado, para não pesar na navegação.

## Capturas

| | |
|---|---|
| ![Jogador 1 entrou](.github/readme/title-ready.jpg) | ![Seleção de perfil](.github/readme/profile-select.jpg) |
| Tela inicial: o jogador 1 entrou; mais um toque no centro começa | Seleção de perfil com CRIAR PERFIL |
| ![Teclado do perfil](.github/readme/profile-keyboard.jpg) | ![Seleção de músicas](.github/readme/song-select.jpg) |
| Nome do perfil digitado pelo tapete | Seleção de músicas, aberta numa música do PHOENIX 2 |
| ![Música escolhida](.github/readme/song-chosen.jpg) | ![Dois jogadores](.github/readme/two-players.jpg) |
| Música escolhida: MY BEST, bola grande e READY | Dois jogadores, cronômetro no centro |
| ![Dois jogadores em READY](.github/readme/two-players-chosen.jpg) | ![Versões](.github/readme/versions.jpg) |
| Os dois jogadores em READY | Roda de grupos: versões |
| ![Categorias](.github/readme/categories.jpg) | ![Níveis de Double](.github/readme/double-levels.jpg) |
| Roda de grupos: categorias | Níveis de Double, do 1 ao 28 |
| ![Janela de comandos](.github/readme/command-window.jpg) | ![Gameplay](.github/readme/gameplay.jpg) |
| Janela de comandos: Auto Velocity | Gameplay com dois jogadores: o receptor do painel pisado brilha |

As capturas mostram o tema com as suas artes, que o `pi/assets.sh` baixa e gera (veja [Artes do tema](#artes-do-tema)).

## Requisitos

- [Project OutFox](https://projectoutfox.com/downloads) 0.5.0-pre043 ou mais novo, no modo `pump`.
- Testado num Raspberry Pi 5 (Raspberry Pi OS, Wayland com Xwayland) a 60 Hz.

## Instalação

### Num Raspberry Pi 5

Quatro passos transformam um Raspberry Pi 5 na máquina de referência. Você precisa do Pi (o de referência tem 8 GB), de um cartão microSD com espaço para as músicas (o de referência usa 128 GB; as músicas ocupam 47 GB), de internet, de uma tela e de um tapete (um teclado também serve).

1. **Grave o sistema.** No [Raspberry Pi Imager](https://www.raspberrypi.com/software/), escolha *Raspberry Pi 5*, depois *Raspberry Pi OS (64-bit)*, a versão com área de trabalho, e depois o seu cartão. Nas configurações do Imager, defina um nome de usuário, uma senha e o Wi-Fi. Grave o cartão, coloque no Pi e ligue.

2. **Instale tudo** com um comando. No Pi, abra o Terminal (o ícone fica na barra de cima), ou conecte por SSH, e cole:

   ```bash
   git clone https://github.com/kalinathalie/hexagono.git ~/.project-outfox/Themes/Infinitesimal && bash ~/.project-outfox/Themes/Infinitesimal/pi/setup.sh
   ```

   Leva cerca de 20 minutos e instala o Project OutFox, este tema com todas as suas artes (vídeo de abertura, cartões, noteskins, ícones de jogador...), 60 Hz em qualquer tela, o jogo abrindo no login, as preferências e o mapeamento do tapete. Ele pede a sua senha e, no meio, mostra a licença das fontes da Microsoft: aceite (escolha `<Ok>` e depois `<Yes>`, com as setas e Enter) para os cartões usarem a mesma fonte da máquina de referência.

   No fim aparece *Done*. Se aparecerem avisos (warnings) antes dele, algo não pôde ser baixado: rode de novo mais tarde só a segunda metade, `bash ~/.project-outfox/Themes/Infinitesimal/pi/setup.sh`, e ele busca o que faltou.

3. **Coloque as músicas.** Copie as pastas de músicas para `~/.project-outfox/Songs`, uma pasta por versão, com nomes como `17 - PHOENIX 2` (veja [Músicas](pi/README.pt-BR.md#músicas)). Depois gere as miniaturas da roda:

   ```bash
   cd ~/.project-outfox/Themes/Infinitesimal && python3 tools/make_thumbs.py
   ```

4. **Reinicie:**

   ```bash
   sudo reboot
   ```

   O Pi entra sozinho e o jogo abre na tela inicial, em 60 Hz.

Pronto: o Pi fica como o de referência, menos o que é pessoal (músicas, perfis, notas) e as noteskins extras: o de referência tem 61, de uma coleção particular; um Pi novo recebe as 11 do XSanity e as 6 do OutFox ([como instalar um conjunto seu](pi/README.pt-BR.md#passos)). Se o tapete não responder, mapeie em INPUT OPTIONS: na tela inicial, pise vermelho esquerdo, vermelho direito, azul esquerdo, azul direito, duas vezes. Cada passo em detalhe: [kit do Raspberry Pi](pi/README.pt-BR.md).

### Em outro computador

Com o [Project OutFox](https://projectoutfox.com/downloads) instalado, clone o tema dentro da pasta [Themes](https://outfox.wiki/user-guide/config/folders/#themes) dele com o nome `Infinitesimal`, gere as artes (veja abaixo) e escolha o tema nas opções do OutFox. No Linux:

```bash
git clone https://github.com/kalinathalie/hexagono.git ~/.project-outfox/Themes/Infinitesimal
```

## Artes do tema

A arte do Pump It Up, do phyrebird e do XSanity **não está neste repositório**. Um comando baixa cada uma da sua origem e gera o resto nas pastas do tema ignoradas pelo git. No Raspberry Pi, o `setup.sh` já roda ele; à mão (no Linux, com Python 3, Pillow, numpy, ffmpeg e node):

```bash
bash ~/.project-outfox/Themes/Infinitesimal/pi/assets.sh
```

A maior parte do tempo vai para os downloads e o vídeo de abertura. Ele pula o que já existe e termina com a lista do que não conseguiu, então rodar de novo completa o trabalho. O que ele cria:

- `Graphics/Phoenix/`: cartões de canal do Phoenix, bolinhas de dificuldade, MY BEST, READY, ícones de nota, janela de comandos, logo do Phoenix 2, vídeo de abertura, animação de estouro e os ícones de jogador.
- `Graphics/XSanity/` e `Graphics/XSCommandWindow/`: as artes do XSanity, e as noteskins de Pump dele em `~/.project-outfox/NoteSkins`.
- `Thumbs/`: as miniaturas da roda, depois que as músicas estão instaladas.

O que faltar é trocado pelos gráficos do próprio tema. Origens e opções: [README do kit](pi/README.pt-BR.md#as-artes-do-tema-assetssh).

## Ferramentas

- `tools/make_thumbs.py`: gera as miniaturas da roda em `Thumbs/`. Rode no computador que tem as músicas e de novo quando adicionar músicas:

  ```bash
  python3 tools/make_thumbs.py
  ```

- `tools/make_phoenix_cards.py`: gera, a partir dos cartões do Phoenix baixados, os cartões de Single Lv. 24 a 26, de Double Lv. 1 a 4 e 26 a 28, de Half-Double e das categorias.
- `tools/make_phoenix_logo.py`: recorta o logo do Phoenix 2 do fundo branco para a tela inicial.
- `tools/make_phoenix_labels.py`: redesenha em 4x, com a fonte do tema, os nomes das categorias da command window (SPEED, DISPLAY, NOTE SKIN, AUTO VELOCITY...), para ficarem nítidos quando ampliados, e acrescenta JUDGE TIMING.

## Herdado do Infinitesimal

Continuam valendo as funções do tema original: janelas de julgamento e barra de vida no estilo K-Pump, outras janelas de timing (StepMania, ITG, Infinity, Pro, Jump), locutor na avaliação, Basic Mode, filtros de fundo, modificadores de aparência e as opções próprias do tema no menu do operador. Veja o [README do Infinitesimal](https://github.com/Team-Infinitesimal/Infinitesimal) para a lista completa.

## Idiomas

Inglês, português do Brasil e polonês.

## Créditos

- **Infinitesimal:** dj505, SheepyChris e toda a equipe listada em `credits.txt`.
- **InfiniteWorlds**, de tiny-goat (GPL-3.0): setas dos cantos e moldura da roda.
- **Pump It Up Phoenix e Phoenix 2**, da Andamiro: referência de layout. Logos e arte do jogo pertencem à Andamiro.
- **XSanity** e **phyrebird**: fontes da arte opcional usada localmente.

## Licença

GPL-3.0, a mesma do Infinitesimal. Veja `LICENSE`.
