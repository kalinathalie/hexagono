# hexagono

Tema do Project OutFox que reproduz o Pump It Up Phoenix 2, feito a partir do Infinitesimal e jogado só pelo tapete, para um Raspberry Pi 5 travado em 60 FPS. `pi/` monta o Pi inteiro; a arte de terceiros é baixada ou gerada por `pi/assets.sh`, nunca commitada.

## Mapa da documentação

Leia só o que a tarefa toca. `docs/` é privado (fora do git) e só existe na máquina de quem mantém o projeto; sem ele, use `README.md`, `pi/README.md` e o código.

- `docs/design.md` — arquitetura, componentes, dados, fluxos e decisões.
- `docs/stack.md` — versões, documentação oficial, convenções e comportamentos do OutFox já verificados. Consulte-a em vez da memória.
- `docs/workflow.md` — papéis, escolha de modelo, fatiamento, briefs, testes e revisão. Leia antes de delegar.
- `docs/pi.md` — acesso ao Pi de referência, deploy e o que pode ser testado nele; scripts em `docs/pi/`.
- `docs/pumpfox-reuse.md` — o que aproveitar do PumpFox (tema Phoenix 1 do mesmo dono): arte, sons e Lua, e as regras para isso. Leia antes de criar arte, animação ou som.
- `docs/specs/<feature>/spec.md` — uma por funcionalidade:
  - `title-screen` — tela inicial: vídeo, PRESS CENTER STEP, entrar e começar, código das opções
  - `profile-select` — perfis: criar pelo tapete, editar nome e foto, READY, tirar um jogador
  - `song-wheel` — roda de músicas, música inicial, transição ao escolher, cronômetro, miniaturas
  - `group-select` — grupos, categorias, gêneros, ordenação e filtro por número de jogadores
  - `chart-row-and-records` — fileira de dificuldades, recordes, MY BEST, bola grande, READY
  - `command-window` — janela de comandos: Speed, Auto Velocity, Display, Note Skin, Judge, Judge Timing
  - `stage-break-and-life` — barra de vida, estouro com 40 erros, animação, jogada quebrada fora dos recordes
  - `gameplay-visuals` — brilho do receptor, explosões das noteskins, notas ocultas
  - `evaluation-and-hud` — HUD das seleções: barras de perfil, cronômetro, setas dos cantos, fundo (a avaliação foi para `evaluation-screen`)
  - `evaluation-screen` — tela de resultado do Phoenix 2: tabela, score, diferença, nota, placa, voz e música
  - `pi-setup` — kit do Pi: sistema, tela a 60 Hz, inicialização, preferências, tapete, perfis reservados
  - `theme-art` — arte de terceiros: `pi/assets.sh`, `pi/assets/`, `tools/make_*`
- `docs/plans/` — planos de implementação por ondas; cada um tem uma seção "Estado" no topo.
- `docs/backlog.md` — pendências: o que está em andamento, o que espera o usuário, prováveis bugs e próximas specs. Comece por aqui ao retomar o trabalho.

## Stack

- Lua 5.1 no motor do Project OutFox 0.5.0-pre043, modo `pump`; testes em LuaJIT 2.1 (PC) ou `lua5.1` (Pi).
- Kit do Pi em bash e Python 3 (biblioteca padrão, Pillow, numpy); ffmpeg e yt-dlp para os vídeos.
- Raspberry Pi 5 com Raspberry Pi OS 64-bit (Debian 13), Wayland com labwc, kanshi e wlr-randr.
- Sem lint nem checagem de tipos: a verificação são os testes.

## Comandos

Comando que ainda não rodou leva `(não verificado: <o que falta>)`. Rode da raiz do repo.

| Para | Comando |
|---|---|
| Instalar tudo num Raspberry Pi 5 | `bash pi/setup.sh`, com o clone em `~/.project-outfox/Themes/Infinitesimal` (passo a passo no `README.md`) (não verificado: a execução completa com `sudo` pede um Pi recém-gravado) |
| Baixar e gerar a arte | `bash pi/assets.sh` (não verificado por inteiro: rodou sem vídeos e XSanity, `--no-video --no-xsanity`) |
| Abrir e fechar o jogo no Pi | `~/.local/bin/outfox-run`, `~/.local/bin/outfox-stop` |
| Um teste Lua (arquivo) | `luajit tests/xscw/run.lua tests/xscw/test_<nome>.lua` (no Pi, `lua5.1`) |
| Um teste Python (arquivo) | `python pi/tests/test_<nome>.py` (no Pi, `python3`) |
| Verificação completa (testes) | `bash tools/verify.sh` (`LUA=` e `PYTHON=` escolhem os interpretadores) |
| Deploy no Pi, a partir do PC | `bash docs/pi/deploy-from-pc.sh` (privado; ver `docs/pi.md`) |

## Estrutura

- `BGAnimations/` — atores de cada tela, pelo nome do OutFox (`ScreenX underlay`, `overlay`, `in`, `out`); a seleção do Phoenix fica em `ScreenSelectMusicFull overlay/` e `underlay/`.
- `Modules/` — lógica em Lua puro carregada com `LoadModule`, testável sem o motor; `PIU/` tem vida, estouro e notas.
- `Scripts/` — carregados pelo motor em ordem numérica: ordenação e grupos, Auto Velocity, branches, sessão, vídeos do Phoenix.
- `metrics.ini` — métricas das telas; `Languages/*.ini` — textos de tela.
- `tests/xscw/` — testes dos módulos; `run.lua` simula o `LoadModule`.
- `pi/` — kit do Raspberry Pi: `setup.sh`, `assets.sh`, `merge_prefs.py`, `assets/` (downloads de arte), `config/` (arquivos instalados), `tests/`.
- `tools/` — geradores de arte (cartões, rótulos, logo, miniaturas) e `verify.sh`.
- Ignorados pelo git: `Graphics/Phoenix/`, `Graphics/XSanity/`, `Graphics/XSCommandWindow/` e `Thumbs/` (feitos por `pi/assets.sh` e `tools/`). `docs/` fica fora do git pelo `.git/info/exclude` local, nunca pelo `.gitignore`.

## Regras

- Antes de mexer numa funcionalidade, leia a spec dela. Mudou o comportamento: atualize a spec na mesma mudança. Funcionalidade nova começa por uma spec.
- Dúvida que afete funcionalidade ou resultado: pergunte ao usuário, não assuma. Escolha trivial e reversível: decida e diga qual foi.
- Siga a documentação oficial de `docs/stack.md`; não confie na memória para versões, APIs e flags.
- Lógica nova vai para um módulo em `Modules/` com teste em `tests/xscw/`, escrito antes; o ator em `BGAnimations/` só liga o módulo ao motor.
- Arte de terceiros (Andamiro, phyrebird, XSanity) nunca entra no git; o que for essencial ao tema, `pi/assets.sh` precisa baixar ou gerar. Exceção: do PumpFox (tema do mesmo dono, privado) entra no repo só o essencial que o tema usa, nunca pastas inteiras (`docs/pumpfox-reuse.md`). Músicas e BGAs nunca entram no repo nem no kit, e BGAs nunca são trocados por clipes de preview.
- Nada de `docs/`, IP, usuário, chave SSH, serial da TV ou caminho pessoal em arquivos commitados. Antes de todo push, confira os commits por arte, mídia, `docs/` e segredos.
- Commit só quando o usuário concordar; push só quando ele pedir.
- No Pi não se joga música por automação (teclas simuladas): quem testa jogando é o usuário. Menus podem ser conferidos com capturas de tela.
- Código, comentários e nomes em inglês; textos de tela em `Languages/`, sempre em `en.ini` e `pt-BR.ini` juntos.

## Delegação

A sessão principal orquestra: conversa com o usuário, decide, fatia, escreve briefs e revisa. O trabalho operacional vai para subagentes, sempre com `model` e `effort` explícitos. Os aliases apontam para a versão mais recente de cada modelo; não fixe versão.

| Tarefa | `model` | `effort` |
|---|---|---|
| Simples: pesquisa, levantamento de código, boilerplate a partir de referência, edição pontual com instrução exata, teste de uma unidade, config | `haiku` | `xhigh` |
| Média/alta: fatia de funcionalidade em poucos arquivos, diagnóstico de bug, integração seguindo a doc, spec a partir de decisões | `sonnet` | `high` |
| Muito robusta, só se não der para fatiar: arquitetura transversal, concorrência, desempenho, segurança, migração de dados | `opus` | `high` |

- Fatie ao máximo: uma preocupação por tarefa; tarefas paralelas nunca tocam o mesmo arquivo.
- Brief completo, conciso e sem redundância, no modelo de `docs/workflow.md`.
- Cada tarefa roda só os testes do que mudou; a verificação completa roda uma vez, no fim de cada onda.
- Se você é um subagente: execute só o seu brief. Não delegue, não rode a verificação completa; se houver dúvida, pare e reporte.
