# Janela de comandos gráfica (estilo PIU/XSanity) para o Infinitesimal

Data: 2026-10-20. Fork pessoal do tema Infinitesimal (branch `xsanity-tweaks`), usado no OutFox 0.5.0 pre-043 num Raspberry Pi 5, modo `pump`, tapete USB de 5 painéis por jogador.

## Intenção

Substituir a janela de modificadores atual, que é o componente de texto do motor (`OptionsList`, lista de linhas), por uma janela desenhada pelo tema, visual e navegável só pelo tapete, no espírito da janela de comandos do Pump It Up Phoenix tal como o XSanity a reproduz: carrossel de categorias com títulos em arte, itens como selos (ícones), descrição, e os painéis de cima servindo de "voltar".

Por quê: o jogador acha a lista de texto difícil de ler e navegar durante o jogo; a janela do XSanity é o modelo mental dele.

## Objetivos

- Toda a navegação com os cinco painéis: painéis de baixo movem (esquerda/direita), Center entra ou aplica, painéis de cima voltam um nível ou fecham.
- Categorias com título gráfico e descrição; itens como selos numa linha horizontal, com o item sob o cursor em destaque e os itens ativos marcados.
- Cobrir todas as categorias do XSanity que tenham equivalente no OutFox/Infinitesimal (lista abaixo).
- Preview de noteskin ao navegar (reaproveitar os atores `NS<skin>` que o tema já pré-carrega).
- Tudo o que a janela aplica deve persistir da mesma forma que hoje (perfil do jogador para mods e noteskin; preferências do Infinitesimal para AV, tipo de velocidade, julgamento, filtro, info de HUD).
- Rodar leve no Raspberry Pi 5: só sprites e texto, sem vídeo, sem recarregar texturas ao navegar.

## Não-objetivos

- Não reimplementar categorias sem equivalente no OutFox: sort, rank, vsmode, judgeskin, zoom do julgamento, lifebar skin, timing adjust por chart, modos NX/UA/DR/SI/RI/SN/ZZ de path.
- Não substituir a tela de seleção de música, a roda de grupos nem a lista de charts; só a janela de modificadores.
- Não tornar o resultado distribuível como parte do Infinitesimal oficial: os gráficos vêm do XSanity e ficam só neste fork pessoal.

## Anti-objetivos (o que tornaria isto um fracasso)

- Travar ou perder input: se a janela "comer" o Center e o jogador não conseguir mais escolher música, está errado.
- Deixar a lista de texto antiga como único caminho para algo que a nova janela diz cobrir.
- Mods aplicados que não aparecem nos ícones de mod ao lado da roda, ou que não persistem na próxima partida.

## Restrições técnicas (verificadas no código)

- O motor engole todo o input enquanto um `OptionsList` está aberto; a janela nova portanto **não usa** `OptionsList`. Ela recebe input por `AddInputCallback`, como `GroupSelect.lua` e `MusicWheel.lua` fazem.
- Os outros componentes da tela já bloqueiam o próprio input quando recebem as mensagens `OptionsListOpened` / `OptionsListClosed` (roda, roda de grupos, lista de charts). A janela nova **emite essas mesmas mensagens** ao abrir e fechar, para não precisar mexer nesses componentes.
- `ModIcons.lua` e `NotefieldPreview.lua` se atualizam na mensagem `OptionsListStart`; a janela nova emite `OptionsListStart` sempre que aplica algo.
- A lista de texto antiga continua existindo e abrindo pelo botão Select (reserva). O código de painéis (DownLeft, DownRight, três vezes) passa a abrir a janela nova.
- Lua 5.1 do motor; sem bibliotecas externas; atores criados em tempo de carga (nada dinâmico).
- Gráficos: copiar `Graphics/CommandWindow` da instalação do XSanity em `C:\Users\kalin\Desktop\PIU\XSanity 0.96.0\XSanity\Themes\xsanity` (o tema dentro dela é a versão 0.99.2) para `Graphics/XSCommandWindow/` no tema: o conjunto principal (títulos `NN_title.png`, folhas `IconsNN AxB.png` tal como existem nessa pasta, moldura `CW/`, setas, cursor). Não usar o conjunto compacto `RESP*` nem os skins de `Mods/CommandWindow`. O índice de frame de cada selo é derivado das tabelas `GetModTitles` de `0_Interface_Full_Command_Window.lua` dessa mesma versão (campo `stateindex`), conferido visualmente folha por folha. Fontes do próprio tema (Montserrat). Sons já existentes: `OpenCommandWindow`, `CloseCommandWindow`, `MoveCommandWindow`, `StartCommandWindow`.
- Enquanto a janela de um jogador está aberta, o callback de input **consome** (retorna `true`) todo input daquele jogador. Assim o motor não roda o detector de códigos da tela (o código DownLeft/DownRight não dispara de novo ao navegar) e nenhum outro componente vê esses toques. `MusicWheel.lua` recebe um guard por jogador para DownLeft/DownRight/Center (hoje só o Back é guardado), porque os callbacks registrados antes do da janela ainda são chamados.
- `OptionsList.lua` (lista antiga) precisa de duas edições pequenas: ignorar `OptionsListOpened/Closed` que venham com o parâmetro `XSWindow=true` (para não deslizar a moldura antiga), e deixar de abrir a lista antiga no código de painéis (`OpenOpList`), mantendo só o Select (`OpenOpListButton`).
- Rush é uma SongOption compartilhada (`MusicRate`): aplicar com `GAMESTATE:ApplyGameCommand("mod,1.2xmusic,no haste", pn)`, como a lista antiga faz, e não via `PlayerOptions`.

## Layout

Painel vertical por jogador (P1 à esquerda, P2 à direita, mesmas posições da janela atual: x = 200 e `SCREEN_RIGHT - 200`, y = `SCREEN_CENTER_Y - 70`), deslizando para dentro ao abrir e para fora ao fechar.

De cima para baixo:

1. Cabeçalho "COMMAND WINDOW" com as setas BACK nos cantos superiores (lembrete de que os painéis de cima voltam).
2. Carrossel de categorias: título da categoria atual em arte (`NN_title.png`) no centro, títulos vizinhos menores e esmaecidos à esquerda e à direita, setas amarelas indicando que os painéis de baixo movem.
3. Área de itens: uma linha horizontal de selos (frames da folha de ícones da categoria), até 7 visíveis, o selo sob o cursor maior e com brilho; selos ativos com cor cheia, inativos em cinza. Em Noteskin, a linha de selos é substituída pelo preview da nota (ator `NS<skin>`, via `ActorProxy`) com o nome da skin embaixo. Em AV e Rush, mostrar o valor atual em número grande ao lado dos selos.
4. Caixa de descrição: uma frase curta da categoria ou do item sob o cursor (strings em `Languages/pt-BR.ini` e `en.ini`).
5. Rodapé com as setas SHIFT (painéis de baixo).

## Navegação

Dois níveis: **categorias** e **itens**.

- No nível de categorias: painéis de baixo movem o carrossel (com repetição ao segurar); Center entra na categoria; painéis de cima fecham a janela.
- No nível de itens: painéis de baixo movem o cursor pelos selos (com repetição); Center aplica/alterna o item; painéis de cima voltam ao nível de categorias.
- Em AV: o cursor fica sobre +100/+10/+1/−1/−10/−100 e o Center aplica o passo (como no XSanity). Em Rush: os selos são os valores; Center seleciona um.
- Categoria "Sair": Center fecha. Categoria "Reset": Center zera os mods do jogador e volta AV/tipo aos padrões (pedir confirmação com um segundo Center dentro de 2 s).
- Repetição de tecla: só os painéis de baixo aceitam `InputEventType_Repeat`; Center e painéis de cima só `FirstPress`.
- Dois jogadores: cada um tem a sua janela e o seu estado; o input é filtrado por `PlayerNumber`. O outro jogador continua livre para rolar a roda e trocar de chart, mas **iniciar a música fica bloqueado enquanto qualquer janela estiver aberta** (o Center de confirmação em `ChartDisplay.lua` é ignorado nesse caso). Ao sair da tela, as janelas são consideradas fechadas.

## Categorias e mapeamento (XSanity → OutFox/Infinitesimal)

Ordem no carrossel e arte do título entre parênteses.

1. **SPEED** (01): 1x, 2x, 3x, 4x, 5x, 6x, +0.25, +0.5, EW, RV, AC, DC. Os "x" e os incrementos gravam `AutoVelocity` (100..600, passo 25/50) com `AutoVelocityType=false` (Multiply). EW = `expand`, RV = `randomspeed`, AC = `boost`, DC = `brake` (alternam, via `PlayerOptions` do nível `ModsLevel_Preferred`).
2. **AUTO VELOCITY** (11): +100, +10, +1, −1, −10, −100 sobre `AutoVelocity` (limites 100..999, como hoje) e três selos de tipo: MULTIPLY / AUTO / CONSTANT (`AutoVelocityType` = false / "Auto" / "Constant"). Depois de gravar, chamar `Player.SetSpeed.lua`.
3. **DISPLAY** (02): V = `hidden`, AP = `sudden`, NS = `stealth`, FD = `dark` (sem receptores), MI = `mini` 20%, BGA OFF / BGA DARK / BGA PARTIAL = filtro de tela do Infinitesimal (`ScreenFilter` 1.0 / 0.7 / 0.4, e 0 para desligar; `UseVideoBackground` fica como está). FL e RANDOM NOTE não existem no OutFox: fora.
4. **NOTE SKIN** (03): todas as noteskins de `pump`, com preview e nome. Center aplica (`PlayerOptions:NoteSkin`).
5. **PATH** (04): efeitos que o OutFox tem: Drunk, Dizzy, Tipsy, Beat, X-Mode (`drunk`, `dizzy`, `tipsy`, `beat`, `45% xmode`), alternáveis. Só X tem ícone no XSanity; os outros usam o selo genérico com texto.
6. **ALTERNATE** (05): Mirror, Random, Super Random, Backwards (`mirror`, `shuffle`, `supershuffle`, `backwards`... usar os nomes de mod que o Infinitesimal já usa na lista Turn). Exclusivos entre si (escolher um desliga os outros), mais um selo OFF.
7. **JUDGE** (06): os modos de timing do Infinitesimal, na ordem de `TimingModes` (Original, ITG, Pump Easy, Pump Normal, Pump Hard, Pump Very Hard, Infinity, Pro, Jump). `SmartTimings` é uma preferência **global** (`Save/OutFoxPrefs.ini`), e `SmartJudgments` (gráfico de julgamento) é por jogador e depende do modo. Ao trocar o modo, a janela grava `SmartTimings` e regrava `SmartJudgments` do jogador com o primeiro gráfico válido para o novo modo (`Modules/Options.SmartJudgeChoices.lua`). Antes de codificar, confirmar no Pi o que a lista antiga grava de fato: trocar o modo nela e comparar `Save/OutFoxPrefs.ini` e o `OutFoxPrefs.ini` do perfil antes e depois (o módulo `Row.Prefs.lua` que faz o save é do OutFox, não do tema).
8. **RUSH** (07): 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170 por cento (`0.6xmusic` ... `1.7xmusic`, `no haste`), exclusivos.
9. **INFO** (14): Score display (Off/Score/Percent), Song progress (on/off), Measure counter (Off/Stream only/All), Offset bar, Pro timing, Hide judgment. Gravam as preferências do Infinitesimal do jogador: `ScoreDisplay`, `SongProgress`, `MeasureCounter`, e os três itens de julgamento como **três chaves separadas** `OffsetBar`, `ProTiming`, `HideJudgment` (é o que `Graphics/Player judgment.lua` lê; `JudgmentItems` é legado).
10. **LIFEBAR** (18): só Pro lifebar (on/off) (`ProLifebar`). "Lifebar position below" é configuração de máquina (menu de serviço), não entra.
11. **RESET** (08): reset completo do jogador, igual ao `ResetLuaMods` de `Scripts/04 Main.lua`: mods (`clearall`), AV=200/Multiply, filtro de tela, contador de compasso, itens de julgamento, score, progresso e pro lifebar. Como `clearall` também zera a noteskin e o tipo de fail, a janela guarda a noteskin antes e a restaura depois; o modo de julgamento não é tocado.
12. **SAIR** (99): fecha.

Onde o XSanity tem ícone equivalente, usar o frame da folha indicada no seu código (`Icons02 13x1` para SPEED, `Icons11 6x1` para AV, `Icons03 13x1` para DISPLAY, `Icons06 3x1` para ALTERNATE, `Icons07 17x1` para JUDGE/RUSH, `Icons09 11x1` para INFO, `Icons19 4x1` para LIFEBAR). Onde não há, selo genérico (`Icons08 1x1`) com texto curto por cima.

## Persistência e integração

- Mods de jogador: `GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")`; o motor grava no perfil.
- AV, tipo, julgamento, filtro e info: `LoadModule("Config.Save.lua")(chave, valor, CheckIfUserOrMachineProfile(n) .. "/OutFoxPrefs.ini")`, as mesmas chaves que `Modules/Options.Prefs.lua` e `Scripts/02 AutoVelocity.lua` usam hoje.
- Depois de qualquer aplicação: `MESSAGEMAN:Broadcast("OptionsListStart", { Player = pn })` para os ícones de mod e o preview do notefield se atualizarem.

## Etapas de entrega (cada uma testável no Pi)

1. Estrutura da janela (moldura, carrossel, itens, descrição, abrir/fechar, input, mensagens) com SPEED, AUTO VELOCITY, NOTE SKIN e SAIR. A lista antiga continua no Select.
2. DISPLAY, JUDGE, RUSH, ALTERNATE, PATH.
3. INFO, LIFEBAR, RESET; polimento: sons, animações, segundo jogador, strings pt-BR/en.

## Decisões já tomadas (do construtor, não do jogador)

- Manter a lista de texto do motor acessível pelo Select como reserva durante as três etapas.
- Itens sem ícone no XSanity usam selo genérico com texto, em vez de arte nova.
- Em DISPLAY, BGA OFF/DARK/PARTIAL viram o filtro de tela do Infinitesimal, sem desligar o vídeo de fundo (desligar vídeo exige reiniciar o jogo no Infinitesimal).
- A janela nova é um arquivo novo (`BGAnimations/ScreenSelectMusicFull overlay/CommandWindow.lua`), carregado em `overlay/default.lua`; `OptionsList.lua` recebe só as duas edições descritas nas restrições; `MusicWheel.lua` e `ChartDisplay.lua` recebem os guards descritos.
- Gráficos vêm do XSanity instalado em `Desktop\PIU` (tema 0.99.2), conjunto principal; frames mapeados pelas tabelas do próprio XSanity.
- JUDGE grava `SmartTimings` global e regrava `SmartJudgments` do jogador; INFO grava as três chaves de julgamento separadas; LIFEBAR só tem Pro lifebar; RESET é completo exceto noteskin e julgamento.
- Com uma janela aberta, o outro jogador navega mas não inicia a música.

## Fica para o construtor

- Posições e tamanhos exatos dos elementos dentro da moldura; quantos selos visíveis por vez.
- Como organizar as tabelas de categorias/itens no Lua (uma tabela declarativa por categoria com `Apply`, `IsActive` e `Describe`).
- Textos das descrições.
