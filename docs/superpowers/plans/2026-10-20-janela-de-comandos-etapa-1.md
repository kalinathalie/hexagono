# Janela de comandos gráfica, etapa 1: plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Uma janela de comandos desenhada pelo tema (moldura, carrossel de categorias, selos, descrição), aberta pelo código de painéis, com as categorias Speed, Auto Velocity, Note Skin e Sair funcionando e persistindo como hoje.

**Architecture:** Dois módulos Lua puros e testáveis (`XSCW.State` para navegação, `XSCW.Categories` para o conteúdo e as ações, com dependências injetadas) e um ator de tela (`CommandWindow.lua`) que só desenha e traduz input em chamadas a esses módulos. A janela emite as mesmas mensagens que a lista antiga (`OptionsListOpened/Closed/Start`, com `XSWindow=true`) para que os outros componentes da tela se comportem como já se comportam.

**Tech Stack:** OutFox 0.5.0 pre-043 (Lua 5.1, atores SM5), tema Infinitesimal branch `xsanity-tweaks`; testes dos módulos puros com LuaJIT no PC (ou `lua5.1` no Pi).

**Spec:** `docs/superpowers/specs/2026-10-20-janela-de-comandos-design.md`

## Global Constraints

- Lua 5.1; sem bibliotecas externas; atores criados em tempo de carga.
- Nunca usar `Def.OptionsList` na janela nova; input via `SCREENMAN:GetTopScreen():AddInputCallback`.
- Enquanto a janela de um jogador está aberta, o callback retorna `true` para todo input desse jogador.
- Center e painéis de cima só reagem a `InputEventType_FirstPress`; painéis de baixo aceitam `FirstPress` e `Repeat`.
- Persistência: AV e tipo em `AutoVelocity` / `AutoVelocityType` via `LoadModule("Config.Save.lua")(chave, valor, CheckIfUserOrMachineProfile(string.sub(pn,-1)-1).."/OutFoxPrefs.ini")`; limites de AV 100..999; noteskin via `GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin(nome)`; mods de velocidade (`expand`, `randomspeed`, `boost`, `brake`) via o mesmo objeto `PlayerOptions`.
- Depois de aplicar qualquer item: `MESSAGEMAN:Broadcast("OptionsListStart", { Player = pn, XSWindow = true })` e, para velocidade, `LoadModule("Player.SetSpeed.lua")(pn)`.
- Gráficos em `Graphics/XSCommandWindow/`, copiados de `C:\Users\kalin\Desktop\PIU\XSanity 0.96.0\XSanity\Themes\xsanity\Graphics\CommandWindow\` (conjunto principal). Frames dos selos: ordem das tabelas `GetModTitles` do XSanity (SPEED: 1x,2x,3x,4x,5x,6x,+0.25,+0.5,EW,RV,AV,AC,DC = frames 0..12 de `Icons02 13x1`; AV: +100,+10,+1,-1,-10,-100 = frames 0..5 de `Icons11 6x1`).
- Textos em `Languages/en.ini` e `Languages/pt-BR.ini`, seção `[XSCommandWindow]`.
- A lista antiga continua abrindo pelo Select (`OpenOpListButton`); o código de painéis (`OpenOpList`) passa a abrir a janela nova.

## Review Focus

1. Perfil novo sem `AutoVelocity` gravado: `GetAV` devolve 200 e a janela mostra 200, nunca `nil` (teste em Task 3).
2. Noteskin do jogador sem ator `NS<skin>` pré-carregado (nome com maiúsculas, skin removida): o preview esconde o proxy e mostra o nome, sem erro de Lua (teste manual em Task 7).
3. Painel de baixo segurado: o cursor anda em repetição; Center segurado não aplica duas vezes; painel de cima segurado não fecha e reabre (teste em Task 2 para o estado; manual em Task 7 para o input).
4. Código de painéis executado com a roda de grupos aberta ou com uma música já escolhida: a janela não abre (teste manual em Task 7; lógica em Task 4 espelha `IsMenuOpen` e as mensagens `OpenGroupWheel/CloseGroupWheel`, `SongChosen/SongUnchosen`).
5. Dois jogadores: a janela do P1 aberta não captura o input do P2, e o Center de início de música do P2 é ignorado enquanto qualquer janela estiver aberta (teste manual em Task 7).

---

### Task 1: Assets da janela

**Files:**
- Create: `Graphics/XSCommandWindow/` (cópia de `Themes/xsanity/Graphics/CommandWindow/` do XSanity instalado, incluindo as subpastas `CW/` e `bg/`; excluir `RESP*`, `previewhelp/`, `previewResume/`, `timing/`)

**Interfaces:**
- Produces: caminhos `THEME:GetPathG("", "XSCommandWindow/<arquivo>")` usados pelas Tasks 4 e 5. Títulos usados na etapa 1: `01_title.png` (Speed), `11_title.png` (Auto Velocity), `03_title.png` (Note Skin), `99_title.png` (Sair). Folhas: `Icons02 13x1.png`, `Icons11 6x1.png`, `Icons08 1x1.png` (selo genérico). Moldura: `CW/BACKGROUND01.png`, `CW/CURCW 1x2.png` (cursor), `CW/ARRCW 1x2.png` (setas), `BackIcon.png`.

- [ ] **Step 1: Copiar os arquivos** com `cp -r` (Git Bash) para `Graphics/XSCommandWindow/`, depois `rm -rf` das pastas excluídas.
- [ ] **Step 2: Verificar** que `ls Graphics/XSCommandWindow | wc -l` é 46 e que `Graphics/XSCommandWindow/CW` tem 9 arquivos; abrir `99_title.png` e `Icons02 13x1.png` com o Read para confirmar que são o título "EXIT"/"Sair" e a folha de 13 selos.
- [ ] **Step 3: Commit** `git add Graphics/XSCommandWindow && git commit -m "XSCW: assets da janela de comandos (XSanity)"`.

### Task 2: Módulo de navegação `XSCW.State`

**Files:**
- Create: `Modules/XSCW.State.lua`
- Test: `tests/xscw/test_state.lua`, `tests/xscw/run.lua` (runner mínimo: carrega cada `test_*.lua`, conta asserts, sai com código 1 se algum falhar)

**Interfaces:**
- Consumes: nada do motor. Recebe `Categories`: lista onde cada entrada tem `Kind` (`"items"`, `"noteskin"` ou `"exit"`) e, para `items`/`noteskin`, `Items` (lista) e `DefaultItem(pn) -> number`.
- Produces: `local NewState = LoadModule("XSCW.State.lua")` então `NewState(Categories, pn)` devolve `S` com campos `Open` (bool), `Level` (`"cat"`|`"item"`), `Cat` (number), `Item` (number) e métodos `S:OpenWindow()`, `S:CloseWindow()`, `S:Move(dir)` (dir = -1 ou 1; devolve `true` se moveu), `S:Enter()` (devolve `"close"`, `"enter"` ou `"apply"`), `S:Back()` (devolve `"back"` ou `"close"`), `S:CurrentCategory()`, `S:CurrentItem()` (nil no nível de categorias ou em `exit`).

- [ ] **Step 1: Escrever os testes** em `tests/xscw/test_state.lua` com três categorias fictícias (items com 3 itens e `DefaultItem` devolvendo 2; noteskin com 5 itens e `DefaultItem` 4; exit):
  - `OpenWindow` deixa `Open=true`, `Level="cat"`, `Cat` inalterado, `Item=1`.
  - `Move(1)` no nível cat vai de 1 a 2; `Move(-1)` em 1 vai para 3 (wrap); `Move` devolve `true`.
  - `Enter` em cat 1 devolve `"enter"`, `Level="item"`, `Item=2` (DefaultItem).
  - `Move(1)` no nível item vai 2→3, `Move(1)` de 3 vai para 1 (wrap).
  - `Enter` no nível item devolve `"apply"` e não muda nível.
  - `Back` no nível item devolve `"back"` e `Level="cat"`; `Back` no nível cat devolve `"close"` e `Open=false`.
  - `Enter` na categoria exit devolve `"close"` e `Open=false`.
  - `CurrentItem()` devolve o item da lista no nível item e `nil` no nível cat.
- [ ] **Step 2: Rodar** `luajit tests/xscw/run.lua` → falha com "module not found" (ou "attempt to call nil").
- [ ] **Step 3: Implementar** `Modules/XSCW.State.lua` devolvendo `function(Categories, pn)`. `LoadModule` do OutFox executa o arquivo e devolve o seu `return`; no runner de testes, `LoadModule` é um stub que faz `dofile("Modules/" .. nome)`.
- [ ] **Step 4: Rodar** `luajit tests/xscw/run.lua` → `OK` com o número de asserts.
- [ ] **Step 5: Commit** `git add Modules/XSCW.State.lua tests && git commit -m "XSCW: estado de navegação da janela"`.

### Task 3: Módulo de conteúdo `XSCW.Categories` (Speed, Auto Velocity, Note Skin, Sair)

**Files:**
- Create: `Modules/XSCW.Categories.lua`
- Test: `tests/xscw/test_categories.lua`

**Interfaces:**
- Consumes: `Deps` injetado: `GetAV(pn)->number`, `SetAV(pn, n)`, `GetAVType(pn)->false|"Auto"|"Constant"`, `SetAVType(pn, t)`, `GetMod(pn, name)->bool`, `SetMod(pn, name, on)`, `GetNoteSkin(pn)->string`, `SetNoteSkin(pn, name)`, `NoteSkinNames` (lista), `Text(key)->string`.
- Produces: `LoadModule("XSCW.Categories.lua")(Deps)` devolve a lista de categorias no formato que `XSCW.State` consome, com campos extras por categoria: `Name` (`"Speed"`, `"AutoVelocity"`, `"NoteSkin"`, `"Exit"`), `Title` (nome do png), `Description` (texto), e por item: `Label`, `Sheet` (nome do png da folha ou `nil` para selo genérico), `Frame` (0-based), `Apply(pn)`, `IsActive(pn)->bool`, `Description`. Categoria NoteSkin: `Kind="noteskin"`, itens com `Label=nome`, sem `Sheet`. A categoria AutoVelocity tem também `Value(pn)->string` (o AV atual para exibir).

- [ ] **Step 1: Escrever os testes** em `tests/xscw/test_categories.lua` com um `Deps` falso (tabelas em memória, `Text` devolve a chave):
  - 4 categorias na ordem Speed, AutoVelocity, NoteSkin, Exit; `Kind` corretos.
  - Speed tem 13 itens; `Items[2].Apply(pn)` (2x) deixa `AV=200` e `AVType=false`; `Items[7].Apply` (+0.25) com AV 200 deixa 225; `Items[9].Apply` (EW) alterna o mod `expand`; `Items[11].Apply` (AV) deixa `AVType="Constant"`.
  - `Items[2].IsActive` é `true` quando `AV=200` e `AVType=false`, `false` quando `AVType="Auto"`.
  - AutoVelocity: itens 1..6 = +100,+10,+1,-1,-10,-100; `+100` com AV 950 clampa em 999; `-100` com AV 150 clampa em 100; itens 7..9 = Multiply/Auto/Constant, `IsActive` conforme `GetAVType`; `Value(pn)` devolve `"200"` com AV 200 e `"200"` quando `GetAV` devolve `nil` (padrão).
  - NoteSkin: um item por nome de `NoteSkinNames`, na mesma ordem; `Apply` chama `SetNoteSkin`; `DefaultItem(pn)` devolve o índice da skin atual (comparação sem distinguir maiúsculas) ou 1.
  - Frames: Speed `Items[1].Frame==0`, `Items[13].Frame==12`, `Sheet=="Icons02 13x1"`; AutoVelocity `Items[6].Frame==5`, `Sheet=="Icons11 6x1"`; itens de tipo com `Sheet==nil`.
- [ ] **Step 2: Rodar** `luajit tests/xscw/run.lua` → falha.
- [ ] **Step 3: Implementar** `Modules/XSCW.Categories.lua`.
- [ ] **Step 4: Rodar** `luajit tests/xscw/run.lua` → `OK`.
- [ ] **Step 5: Commit** `git add Modules/XSCW.Categories.lua tests && git commit -m "XSCW: categorias Speed, Auto Velocity, Note Skin e Sair"`.

### Task 4: Ator da janela `CommandWindow.lua`

**Files:**
- Create: `BGAnimations/ScreenSelectMusicFull overlay/CommandWindow.lua`
- Modify: `Languages/en.ini`, `Languages/pt-BR.ini` (seção `[XSCommandWindow]`: `Speed`, `AutoVelocity`, `NoteSkin`, `Exit`, uma descrição por categoria `Speed_Desc` etc., `Multiply`, `Auto`, `Constant`)

**Interfaces:**
- Consumes: Tasks 1, 2 e 3. `Deps` reais: `GetAV` lê `AutoVelocity` com `LoadModule("Config.Load.lua")` (padrão 200), `SetAV` grava e chama `Player.SetSpeed.lua`; `GetAVType/SetAVType` idem com `AutoVelocityType` (gravar `tostring(false)` como `Scripts/04 Main.lua` faz); `GetMod/SetMod` via `PlayerOptions` (`ModsLevel_Preferred`): `expand`→`Expand`, `randomspeed`→`RandomSpeed`, `boost`→`Boost`, `brake`→`Brake` (métodos getter/setter do PlayerOptions); `Text` = `THEME:GetString("XSCommandWindow", key)`.
- Produces: mensagens `OptionsListOpened` / `OptionsListClosed` / `OptionsListStart` com `{ Player = pn, XSWindow = true }`; som `OpenCommandWindow` ao abrir, `CloseCommandWindow` ao fechar, `MoveCommandWindow` ao mover, `StartCommandWindow` ao aplicar.

- [ ] **Step 1: Estrutura por jogador**: `for pn in ivalues(GAMESTATE:GetHumanPlayers())`, um `Def.ActorFrame` em `xy(pn == PLAYER_1 and -260 or SCREEN_RIGHT + 260, SCREEN_CENTER_Y - 40)` que desliza para `x = 200` / `SCREEN_RIGHT - 200` ao abrir (`easeoutexpo(0.4)`), com filhos nomeados: `Frame` (sprite `CW/BACKGROUND01.png`, `zoomto(280, 460)`), `Header` (BitmapText "COMMAND WINDOW", fonte `Montserrat extrabold 40px`, zoom 0.45, y -200), `BackHint` (sprite `BackIcon.png`, y -200, x -110), `TitlePrev`/`TitleCur`/`TitleNext` (um sprite por categoria carregado uma vez; as três posições são atualizadas trocando `visible`/`xy`/`zoom`: atual zoom 0.9 em y -110, vizinhos zoom 0.5 e `diffusealpha(0.4)` em x ±100), `Items` (7 slots, x de -108 a 108 passo 36, y 0; cada slot: `Sprite` para `Icons02 13x1`, `Sprite` para `Icons11 6x1`, `Sprite` para `Icons08 1x1` + `BitmapText` por cima; só um visível), `Cursor` (sprite `CW/CURCW 1x2.png` atrás do slot central, `setstate(0)`, pulsando com `diffuseshift`), `SkinPreview` (ActorProxy + BitmapText, como em `OptionsList.lua`, visível só em NoteSkin), `Value` (BitmapText grande, y 60, só em AutoVelocity), `Description` (BitmapText, `Montserrat normal 20px`, zoom 0.5, y 150, `wrapwidthpixels(500)`), `ShiftHint` (sprite `CW/ARRCW 1x2.png`, y 200).
- [ ] **Step 2: Estado e redraw**: criar `State = NewState(Categories, pn)` no `InitCommand`; um comando `Redraw` no frame que posiciona títulos pelo `State.Cat`, preenche os 7 slots com os itens `State.Item-3 .. State.Item+3` (com wrap; slots além do tamanho da lista ficam invisíveis quando a lista tem menos de 7), destaca o item central (`zoom(1.0)` vs `0.8`), marca ativos (`diffuse(1,1,1,1)`) e inativos (`diffuse(0.45,0.45,0.45,1)`), e troca a descrição (categoria no nível cat, item no nível item). Em NoteSkin, esconde os slots e mostra `SkinPreview` com o alvo `NS<skin>` da linha atual. Em AutoVelocity, `Value` mostra `Categories[2].Value(pn)`.
- [ ] **Step 3: Abertura**: `CodeMessageCommand` com `params.Name == "OpenOpList"` e `params.PlayerNumber == pn`, só se `not State.Open and CanOpen[pn]`, onde `CanOpen` fica `false` entre `OpenGroupWheel`/`CloseGroupWheel` e entre `SongChosen`/`SongUnchosen` (handlers de mensagem no frame). Ao abrir: `State:OpenWindow()`, broadcast `OptionsListOpened`, som, slide, `Redraw`.
- [ ] **Step 4: Input**: `AddInputCallback` no `OnCommand` do frame raiz (um callback para todos os jogadores). Para `event.PlayerNumber == pn` com `State.Open`: `DownLeft`/`DownRight` (`FirstPress` ou `Repeat`) → `State:Move(±1)`, som `MoveCommandWindow`, `Redraw`; `Center` (`FirstPress`) → `State:Enter()`: `"enter"` → `Redraw`; `"apply"` → `Item.Apply(pn)`, broadcast `OptionsListStart`, som `StartCommandWindow`, `Redraw`; `"close"` → fechar. `UpLeft`/`UpRight` (`FirstPress`) → `State:Back()`: `"back"` → `Redraw`; `"close"` → fechar. Qualquer outro botão desse jogador é ignorado. Em todos os casos o callback devolve `true` enquanto `State.Open`. Fechar = broadcast `OptionsListClosed`, som `CloseCommandWindow`, slide para fora.
- [ ] **Step 5: Verificar sintaxe** com `luajit -bl "BGAnimations/ScreenSelectMusicFull overlay/CommandWindow.lua" > /dev/null` (só compila) e com o checador de balanceamento já usado no projeto.
- [ ] **Step 6: Commit** `git add "BGAnimations/ScreenSelectMusicFull overlay/CommandWindow.lua" Languages && git commit -m "XSCW: ator da janela de comandos (etapa 1)"`.

### Task 5: Ligações com a tela existente

**Files:**
- Modify: `BGAnimations/ScreenSelectMusicFull overlay/default.lua` (linha com `LoadActor("OptionsList")`)
- Modify: `BGAnimations/ScreenSelectMusicFull overlay/OptionsList.lua` (handlers `OptionsListOpened/Closed` do frame e dos sons; `CodeMessageCommand` do `Def.OptionsList`)
- Modify: `BGAnimations/ScreenSelectMusicFull underlay/MusicWheel.lua` (`InputHandler`)
- Modify: `BGAnimations/ScreenSelectMusicFull underlay/ChartDisplay.lua` (`InputHandler`, ramo Start)

**Interfaces:**
- Consumes: mensagens com `XSWindow=true` da Task 4; `OptionsOpen` (MusicWheel) e `PlayerCanMove` (ChartDisplay) já existentes.

- [ ] **Step 1: `overlay/default.lua`**: logo após `LoadActor("OptionsList"),` inserir `LoadActor("CommandWindow"),`.
- [ ] **Step 2: `OptionsList.lua`**: nos handlers `OptionsListOpenedMessageCommand` e `OptionsListClosedMessageCommand` do frame do jogador e no `Def.Sound` de fechar, começar com `if params.XSWindow then return end`; no `CodeMessageCommand` do `Def.OptionsList`, remover a condição `(params.Name == "OpenOpList" and not MenuButtonsOnly)`, deixando só `params.Name == "OpenOpListButton"`.
- [ ] **Step 3: `MusicWheel.lua`**: no `InputHandler`, logo após o bloco de entrada de jogador (`else` da verificação de `IsSideJoined`), inserir `if OptionsOpen[pn] then return end` antes de `if not IsBusy then`.
- [ ] **Step 4: `ChartDisplay.lua`**: no ramo `button == "Start" or ... "Center"`, antes de `if ConfirmStart[pn] then`, inserir `if not (PlayerCanMove[PLAYER_1] and PlayerCanMove[PLAYER_2]) then return end`.
- [ ] **Step 5: Verificar** balanceamento dos quatro arquivos com o checador; `luajit -bl` em cada um.
- [ ] **Step 6: Commit** `git commit -am "XSCW: ligar a janela nova à tela de seleção; lista antiga só pelo Select"`.

### Task 6: Levar ao Pi

**Files:** branch `xsanity-tweaks` inteira (inclui 3,2 MB de gráficos).

- [ ] **Step 1: Canal binário**: (A) chave SSH do PC autorizada no Pi e `scp -r` da pasta do tema; ou (B) repositório Git remoto (GitHub privado do usuário) com `git push` aqui e `git pull` lá. Decidido com o usuário antes desta task.
- [ ] **Step 2: Transferir** a branch; no Pi: `git log --oneline -1` igual ao do PC; `ls ~/.project-outfox/Themes/Infinitesimal/Graphics/XSCommandWindow | wc -l` = 46.
- [ ] **Step 3: Sintaxe no Pi**: `luac5.1 -p` nos cinco arquivos Lua tocados.

### Task 7: Aceitação no jogo (manual, no Pi)

- [ ] **Step 1**: Código de painéis abre a janela com som; painel de cima no nível de categorias fecha com som; a roda não se move durante a navegação.
- [ ] **Step 2**: Speed: escolher 3x → ícone de mod ao lado da roda mostra 3x; jogar uma música e confirmar a velocidade; reabrir o jogo e confirmar que persistiu.
- [ ] **Step 3**: Auto Velocity: +10 três vezes mostra o valor subindo; Constant marcado; AV 580 com Constant aplicado no gameplay.
- [ ] **Step 4**: Note Skin: navegar mostra o preview e o nome; Center aplica; o ícone de mod troca; skin persiste após reiniciar.
- [ ] **Step 5**: Sair fecha. Select ainda abre a lista antiga. Com a roda de grupos aberta ou com uma música escolhida, o código de painéis não abre a janela.
- [ ] **Step 6**: Segurar painel de baixo rola em repetição; segurar Center aplica uma vez; segurar painel de cima volta uma vez.
- [ ] **Step 7** (se houver segundo tapete): P2 navega com a janela do P1 aberta; o Center de início do P2 é ignorado até a janela fechar.
