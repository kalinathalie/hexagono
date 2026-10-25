# Hexágono: Infinitesimal no estilo Pump It Up Phoenix

Tema de Project OutFox que reproduz as telas do **Pump It Up Phoenix** (e do Phoenix 2), feito a partir do [Infinitesimal](https://github.com/Team-Infinitesimal/Infinitesimal). O Infinitesimal original é inspirado no Pump It Up Infinity. Este fork troca essa base pelo Phoenix: tela inicial, seleção de perfil, seleção de músicas, roda de grupos, janela de comandos e gameplay foram refeitas para funcionar como no fliperama, tudo pelo tapete.

Foi feito para rodar num Raspberry Pi 5 com tapete USB, travado em 60 FPS.

*An OutFox theme that recreates the Pump It Up Phoenix screens, forked from Infinitesimal (which follows Pump It Up Infinity).*

![Tela inicial](.github/readme/title.jpg)

## O que muda em relação ao Infinitesimal

- **Tela inicial de fliperama:** sem menu. O centro do tapete entra o jogador e um segundo toque começa; o outro lado pode entrar antes. Com o vídeo do Phoenix 2 (arte local), a abertura toca uma vez e a espera fica em loop sem emenda. O código vermelho esquerdo, vermelho direito, azul esquerdo, azul direito, duas vezes, abre as opções.
- **Criar perfil pelo tapete:** na seleção de perfil, CRIAR PERFIL abre um teclado na tela. Os azuis escolhem a tecla, o centro aperta e os vermelhos apagam.
- **Começa na versão mais nova:** cada jogo novo abre a seleção numa música aleatória da última versão (hoje o PHOENIX 2). Depois de jogar, a seleção volta para a música jogada.
- **Seleção de músicas no layout do Phoenix:** faixa de preview com o BGA no centro e cópias espelhadas nas laterais, título com artista e BPM, roda de jaquetas 4:3 com setas amarelas na música selecionada e 13 bolinhas de dificuldade com a nota recorde de cada chart.
- **Cronômetro no centro:** as barras de perfil do P1 e do P2 ficam dos lados do cronômetro, com nível, nome e vidas.
- **Transição ao escolher a música:** a roda sai, as bolinhas sobem e cada jogador ganha o painel MY BEST com nota, grade e placa, a bola grande do chart e o selo READY. Os vermelhos no READY tiram só o READY; de novo, voltam para a roda.
- **Roda de grupos com cartões do Phoenix:** versões do jogo, níveis de Single, Double (do 1 ao 28) e Half-Double, especiais e uma tela de categorias, cada uma com seu cartão.
- **Janela de comandos gráfica:** abre com o código de painéis (baixo-esquerda, baixo-direita, três vezes), também durante a escolha da dificuldade, e é navegada só pelo tapete. Tem Speed, Auto Velocity, Display e Note Skin, com prévia da nota.
- **Auto Velocity no modo do PIU:** a velocidade acompanha o BPM, então as gimmicks continuam funcionando. A velocidade constante segue disponível como opção.
- **Gameplay como no fliperama:** a música só é perdida com 40 erros seguidos, sem tela de notas depois; brilho no receptor do painel pisado e explosão em todo acerto, com qualquer noteskin; notas marcadas como ocultas nos charts (gimmicks) ficam invisíveis.
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

As capturas usam a arte opcional descrita abaixo, que não vem no repositório.

## Requisitos

- [Project OutFox](https://projectoutfox.com/downloads) 0.5.0-pre043 ou mais novo, no modo `pump`.
- Testado num Raspberry Pi 5 (Raspberry Pi OS, Wayland com Xwayland) a 60 Hz.

## Instalação

Clone o repositório dentro da pasta [Themes](https://outfox.wiki/user-guide/config/folders/#themes) do OutFox, com o nome `Infinitesimal`:

```bash
git clone https://github.com/kalinathalie/hexagono.git Infinitesimal
```

Depois escolha o tema nas opções de aparência do OutFox.

## Arte opcional

A arte do Pump It Up e do XSanity pertence aos seus donos e **não está neste repositório**. O tema procura essas pastas localmente e, quando não encontra, usa os próprios gráficos ou texto:

| Pasta | Conteúdo | Sem ela |
|---|---|---|
| `Graphics/Phoenix/` | cartões de canal, bolinhas, bola grande, painel MY BEST, READY, cursores, ícones de nota, setas, janela de comandos, logo e vídeo de abertura do Phoenix 2 | gráficos do XSanity ou do próprio tema; sem o vídeo, a tela inicial mostra o logo |
| `Graphics/XSanity/` | bolinhas, rótulos de nota, faixa do título, corações e cartões de nível, tirados de uma instalação do XSanity | gráficos do próprio tema |
| `Graphics/XSCommandWindow/` | a janela de comandos no estilo do XSanity | sem nenhuma das duas janelas, o código de painéis abre a lista de opções do OutFox |
| `Thumbs/` | miniaturas de 400x300 da roda | banners do cache do OutFox |

Todas essas pastas estão no `.gitignore`.

## Ferramentas

- `tools/make_thumbs.py`: gera as miniaturas da roda em `Thumbs/`. Rode no computador que tem as músicas e de novo quando adicionar músicas:

  ```bash
  python3 tools/make_thumbs.py
  ```

- `tools/make_phoenix_cards.py`: gera, a partir da arte local do Phoenix, os cartões de Double Lv. 1 a 4 e 26 a 28, de Half-Double e das categorias.

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
