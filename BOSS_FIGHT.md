# Boss Fight - Room 100

## Visao Geral

Quando o jogador atinge a room de numero `BOSS_ROOM_NUMBER` (configuravel em `game_manager.gd`, default 100), o sistema de rooms gera automaticamente uma sala especial de boss no lugar de uma sala normal. Essa sala tem o dobro da altura (320px vs 160px) e contem todos os elementos da boss fight: um carro que o player "entra", caixas que descem do topo e balas que o player dispara para cima.

## Arquivos

Todos os arquivos do boss ficam em `scenes/boss/`:

```
scenes/boss/
  boss_room.gd      Orquestrador principal (a sala em si)
  boss_car.gd       Carro que o player dirige
  boss_box.gd       Caixas que descem do topo
  boss_bullet.gd    Projeteis disparados pelo player
```

Arquivos do core que foram modificados para suportar o boss:

```
scripts/game_manager.gd   Flag boss_defeated, sinal boss_fight_triggered, constante BOSS_ROOM_NUMBER
scripts/main.gd           Logica de criacao da boss room no sistema de rooms
scripts/player.gd         Modo boss_fight_mode (montar no carro, atirar)
scripts/camera_2d.gd      Flag is_locked para travar camera durante a luta
```

## Arquitetura

A boss room e integrada ao sistema de rooms existente -- nao e um overlay ou cena separada. Quando `main.gd` vai criar a room de indice `BOSS_ROOM_NUMBER`, em vez de instanciar `room.tscn`, cria um `Node2D` com o script `boss_room.gd`. A boss room ocupa 2 slots de room (320px de altura), entao o slot seguinte (`BOSS_ROOM_NUMBER + 1`) e pulado.

```
         main.gd
            |
     create_room(index)
            |
    index == BOSS_ROOM_NUMBER?
         /        \
       Sim         Nao
        |            |
  create_boss_room()  room.tscn normal
        |
  boss_room.gd (Node2D)
   |    |    |     |
  Car  Boxes Floor Walls
```

## Fluxo da Boss Fight

```
1. Player sobe normalmente pelas rooms
                    |
2. Room BOSS_ROOM_NUMBER e criada pelo sistema de rooms
   (boss_room.gd cria: chao, paredes, fundo, carro, caixas escondidas)
                    |
3. Player entra na sala caminhando normalmente (auto-walk)
   - EntryDetector chama GameManager.add_room()
   - Carro esta visivel mas PARADO, sem colisao fisica
   - Caixas estao ESCONDIDAS
                    |
4. Player caminha ATE o carro e "entra" nele
   - Area2D (PlayerDetector) no carro detecta o corpo do player
   - car.player_entered emitido -> boss_room._on_car_player_entered()
                    |
5. start_fight() e chamado:
   - player.enter_boss_fight(car, self)
     - Player desativa colisao propria (layer=0, mask=0)
     - Player entra em boss_fight_mode
   - car.start_moving()
     - Carro ativa colisao (layer=1, mask=1) e comeca a se mover
   - Camera trava no centro da sala
   - Todas as caixas sao ativadas (ficam visiveis e comecam a descer)
                    |
6. Durante a luta:
   - Carro anda automaticamente esquerda/direita, quicando nas paredes
   - Player fica "montado" no carro (posicao sincronizada a cada frame)
   - Apertar ESPACO/ENTER (ui_accept) dispara bala para cima
   - Balas sobem e destroem caixas ao colidir
   - Caixas descem cada vez mais rapido com o tempo
                    |
7. Condicoes de fim:
   VITORIA: Todas as 10 caixas destruidas
     -> on_boss_defeated()
     -> Player sai do boss_fight_mode
     -> Camera destrava
     -> Escada de vitoria aparece no centro da sala
     -> Jogo continua normalmente

   DERROTA: Qualquer caixa atinge o chao (death_line_y) ou encosta no carro
     -> game_over.tscn
```

## Componentes

### boss_room.gd (Orquestrador)

Extends `Node2D`. Cria toda a sala proceduralmente em `_ready()`.

**Elementos criados:**
- Background escuro (640px de altura, z_index=-5, cobre rooms atras)
- Chao com tiles (StaticBody2D, one_way_collision)
- Paredes esquerda/direita com tiles (StaticBody2D)
- EntryDetector (Area2D, chama GameManager.add_room)
- Carro (CharacterBody2D com boss_car.gd)
- 10 Caixas (Area2D com boss_box.gd, layout piramide invertida 3-4-3)

**Variaveis de estado:**
- `boxes_remaining` - Conta regressiva de caixas (comeca em 10)
- `fight_active` - True durante a luta
- `fight_over` - True apos vitoria ou derrota (evita triggers duplicados)

**Sinais conectados:**
- `car.player_entered` -> `_on_car_player_entered()` (inicia a luta)
- `box.box_destroyed` -> `_on_box_destroyed()` (decrementa contador)
- `box.box_reached_floor` -> `_on_box_reached_floor()` (game over)

### boss_car.gd (Carro)

Extends `CharacterBody2D`. Veiculo que o player "dirige".

**Comportamento:**
- Comeca PARADO e sem colisao fisica (player atravessa)
- Tem um `PlayerDetector` (Area2D) que emite `player_entered` quando o player caminha ate ele
- Apos `start_moving()`: ativa colisao e anda esquerda/direita a 200px/s, quicando nas paredes
- Pertence ao grupo `"boss_car"` (usado pelas caixas para detectar colisao)

**Ciclo de vida:**
```
_ready()
  collision_layer = 0, collision_mask = 0
  set_physics_process(false)
  Cria PlayerDetector (Area2D)
      |
Player caminha ate o carro
  PlayerDetector.body_entered -> player_entered.emit()
  PlayerDetector e removido (queue_free)
      |
start_moving()
  collision_layer = 1, collision_mask = 1
  set_physics_process(true)
  Carro comeca a se mover
```

### boss_box.gd (Caixas)

Extends `Area2D`. Obstaculos que descem do topo.

**Comportamento:**
- Comeca ESCONDIDA e CONGELADA (`visible = false`, `set_physics_process(false)`)
- Apos `activate()`: fica visivel e comeca a descer
- Velocidade de descida: `descent_speed + (0.5 * time_alive)` px/s (acelera com o tempo)
- Ao ser atingida por bala: flash branco (0.05s) -> `box_destroyed` -> `queue_free()`
- Ao atingir `death_line_y` ou encostar no carro: `box_reached_floor`

**Collision layers:**
- `collision_layer = 0` (caixas nao sao detectadas por outros)
- `collision_mask = 33` (32 = balas do boss, 1 = corpo do carro)
- `monitoring = true` (detecta areas e bodies entrando)
- `monitorable = true` (pode ser detectada por outros)

**Layout na sala (piramide invertida 3-4-3):**
```
    [BOX]  [BOX]  [BOX]         Linha 1: Y=30, 3 caixas
  [BOX] [BOX] [BOX] [BOX]      Linha 2: Y=65, 4 caixas
    [BOX]  [BOX]  [BOX]         Linha 3: Y=100, 3 caixas
```
Espacamento horizontal: 60px entre caixas.

### boss_bullet.gd (Balas)

Extends `Area2D`. Projeteis disparados pelo player.

**Comportamento:**
- Move para cima a 500 px/s
- Auto-destruicao apos 2 segundos
- Pertence ao grupo `"boss_bullet"` (usado pelas caixas para detectar impacto)

**Collision layers:**
- `collision_layer = 32` (bit 5, camada dedicada para balas do boss)
- `collision_mask = 0` (bala nao detecta nada; e a CAIXA que detecta a bala)
- `monitoring = false`, `monitorable = true`

**Criacao:** O player cria balas em `shoot_boss_bullet()` dentro de `player.gd`. A bala e adicionada como filha da `boss_room` (nao do player) para que sua posicao seja relativa a sala.

## Modificacoes no Player (player.gd)

**Variaveis adicionadas:**
```
var boss_fight_mode = false
var boss_car: Node2D = null
var boss_room: Node2D = null
var boss_shoot_cooldown = 0.0
const BOSS_SHOOT_COOLDOWN = 0.3
```

**enter_boss_fight(car, room):**
- Ativa `boss_fight_mode`
- Desativa colisao do player (`collision_layer = 0`, `collision_mask = 0`) para nao empurrar o carro
- Guarda referencias ao carro e a sala

**exit_boss_fight():**
- Desativa `boss_fight_mode`
- Restaura colisao (`collision_layer = 1`, `collision_mask = 27`)

**process_boss_fight(delta):**
- Chamado em `_physics_process` quando `boss_fight_mode == true`
- Sincroniza posicao do player com o carro: `x = car.x`, `y = car.y - 16`
- Sincroniza direcao (flip do sprite)
- `ui_accept` pressionado = dispara bala (com cooldown de 0.3s)

**shoot_boss_bullet():**
- Cria Area2D com boss_bullet.gd
- Adiciona como filho da boss_room (posicao global correta)
- Posicao inicial: 12px acima do player

## Modificacoes na Camera (camera_2d.gd)

```
var is_locked = false
```

Quando `is_locked == true`, a camera para de seguir o player e so processa o efeito de shake. A posicao Y e travada pelo `boss_room.gd` no centro da sala.

## Modificacoes no GameManager (game_manager.gd)

```
signal boss_fight_triggered
var boss_defeated = false
const BOSS_ROOM_NUMBER = 10
```

- `add_room()`: Ao atingir `BOSS_ROOM_NUMBER`, emite `boss_fight_triggered`
- `reset()`: Reseta `boss_defeated = false`
- A flag `boss_defeated` impede que a boss room seja criada novamente se o jogador passar pelo mesmo indice de room

## Modificacoes no Main (main.gd)

**create_room(index):**
- Se `index == BOSS_ROOM_NUMBER` e boss nao foi derrotado: chama `create_boss_room(index)`
- Se `index == BOSS_ROOM_NUMBER + 1` e boss room ja foi criada: pula (boss room ocupa 2 slots)

**create_boss_room(index):**
- Carrega `boss_room.gd` e cria um `Node2D` com esse script
- Posiciona 160px mais alto que uma room normal (para cobrir 2 slots)
- Marca `highest_room_created = index + 1` (2 slots ocupados)

## Collision Layers (Referencia)

| Bit | Layer | Usado por |
|-----|-------|-----------|
| 1   | 1     | Player, Carro, Paredes, Chao |
| 2   | 2     | Escadas |
| 4   | 8     | Inimigos |
| 5   | 16    | Rocks/Obstaculos |
| 6   | 32    | Balas do boss |

## Constantes Ajustaveis

| Constante | Valor | Arquivo | Descricao |
|-----------|-------|---------|-----------|
| `BOSS_ROOM_NUMBER` | 100* | game_manager.gd | Em qual room o boss aparece |
| `CAR_SPEED` | 200.0 | boss_car.gd | Velocidade do carro (px/s) |
| `BOSS_SHOOT_COOLDOWN` | 0.3 | player.gd | Tempo entre tiros (s) |
| `BULLET_SPEED` | 500.0 | boss_bullet.gd | Velocidade da bala (px/s) |
| `LIFETIME` | 2.0 | boss_bullet.gd | Tempo de vida da bala (s) |
| `BOX_DESCENT_SPEED` | 10.0 | boss_room.gd | Velocidade inicial das caixas (px/s) |
| `SPEED_INCREASE_RATE` | 0.5 | boss_box.gd | Aceleracao das caixas (px/s por segundo) |
| `TOTAL_BOXES` | 10 | boss_room.gd | Numero de caixas |

*Para testes rapidos, altere `BOSS_ROOM_NUMBER` para um valor menor (ex: 5).

## Diagrama da Sala

```
+---------- 360px ----------+
|                            |  Y=0 (topo da boss room)
|   [BOX]  [BOX]  [BOX]     |  Y=30
| [BOX] [BOX] [BOX] [BOX]   |  Y=65
|   [BOX]  [BOX]  [BOX]     |  Y=100
|                            |
|       ^ ^ ^ ^ ^            |
|       | | | | |            |
|      balas sobem           |
|                            |
|                            |
|     [PLAYER]               |
|     [==CARRO==]            |  Y~304
|____________________________| Y=314 (chao)
+----------------------------+
```
