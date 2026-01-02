# Sistema de Geração de Rooms - High Up

Este documento explica em detalhes como funciona o sistema de geração procedural de salas (rooms) no jogo High Up.

---

## Índice

1. [Visão Geral da Arquitetura](#visão-geral-da-arquitetura)
2. [Componentes Principais](#componentes-principais)
3. [Fluxo de Criação de Rooms](#fluxo-de-criação-de-rooms)
4. [Sistema de Layouts](#sistema-de-layouts)
5. [Rooms Split vs Simple](#rooms-split-vs-simple)
6. [Sistema de Filtragem de Powerups](#sistema-de-filtragem-de-powerups)
7. [Gerenciamento Dinâmico](#gerenciamento-dinâmico)
8. [Exemplos Práticos](#exemplos-práticos)

---

## Visão Geral da Arquitetura

O jogo usa um sistema de geração procedural infinita de salas verticais. O player sobe constantemente, e novas salas são geradas à frente enquanto salas antigas são removidas atrás.

```
         ┌─────────────────┐
         │   Room N+5      │ ← Gerada dinamicamente
         ├─────────────────┤
         │   Room N+4      │
         ├─────────────────┤
         │   Room N+3      │
         ├─────────────────┤
         │   Room N+2      │
         ├─────────────────┤
         │   Room N+1      │
         ├─────────────────┤
    ┌───>│   Room N        │ ← Player está aqui
    │    ├─────────────────┤
    │    │   Room N-1      │
    │    ├─────────────────┤
    │    │   Room N-2      │
    │    ├─────────────────┤
    │    │   ...           │
    └────┤   Room 0        │ ← Room inicial (vazia)
         └─────────────────┘
              (removidas quando muito abaixo)
```

### Constantes Principais

```gdscript
const ROOM_HEIGHT = 160         # Altura de cada sala em pixels
const SCREEN_HEIGHT = 640       # Altura da tela do jogo
const INITIAL_ROOMS = 5         # Salas criadas no início
const ROOMS_AHEAD = 5           # Salas geradas à frente do player
const ROOMS_BEHIND = 3          # Salas mantidas atrás do player
const CLEANUP_THRESHOLD = 10    # Remove salas >10 posições abaixo
```

---

## Componentes Principais

### 1. **main.gd** - Controlador Principal

Responsabilidades:
- Criar salas iniciais (`create_rooms()`)
- Gerenciar geração dinâmica (`manage_rooms()`)
- Calcular posição do player (`get_current_room_index()`)
- Limpar salas antigas (`cleanup_old_rooms()`)

### 2. **room.gd** - Estrutura da Sala

Cada room contém:
- Piso (floor) com tiles aleatórios
- Paredes laterais (esquerda/direita)
- Escada (ladder) - lado alternado
- Flag `is_split_room` para salas especiais

### 3. **room_manager.gd** - Gerenciador de Layouts

Responsabilidades:
- Escolher layout aleatório para cada sala
- Filtrar layouts especiais (powerups)
- Evitar repetição de layouts
- Separar layouts "simple" vs "split"

### 4. **Layouts** - Conteúdo das Salas

Scripts individuais que definem:
- Posicionamento de enemies
- Posicionamento de collectibles (diamantes, corações)
- Posicionamento de powerups (mist, magnet, invincible, metal)
- Obstáculos especiais (sawblades, cannons, spikes)

---

## Fluxo de Criação de Rooms

### Inicialização (main.gd → _ready)

```
1. GameManager.reset()
   └─> Reseta estado do jogo

2. create_rooms()
   └─> Cria 5 salas iniciais (índices 0-4)
       └─> Room 0: VAZIA (sem layout)
       └─> Rooms 1-4: Recebem layouts aleatórios

3. find_player()
   └─> Localiza o player na cena
```

### Criação de uma Room Individual

```gdscript
func create_room(index: int):
    # 1. Instancia a cena base da room
    var room = room_scene.instantiate()

    # 2. Determina se é split room (a cada 5 salas)
    var is_split = (index > 0 and index % 5 == 0)

    # 3. Define lado da escada (alterna 0/1)
    if not is_split:
        room.ladder_side = index % 2

    # 4. Calcula posição Y (salas crescem para cima)
    var y_pos = (SCREEN_HEIGHT - ROOM_HEIGHT) - (index * ROOM_HEIGHT)
    room.position = Vector2(0, y_pos)

    # 5. Adiciona à árvore
    add_child(room)

    # 6. Popula com layout (exceto Room 0)
    if index > 0:
        room_manager.populate_room(room, index)
```

### Cálculo da Posição Y

```
Room 0: Y = 480  (640 - 160 - 0*160)   ← Sala inicial (tela visível)
Room 1: Y = 320  (640 - 160 - 1*160)   ← Primeira sala acima
Room 2: Y = 160  (640 - 160 - 2*160)
Room 3: Y = 0    (640 - 160 - 3*160)
Room 4: Y = -160 (640 - 160 - 4*160)   ← Salas continuam para cima
...
```

---

## Sistema de Layouts

### Tipos de Layouts

#### 1. **Simple Layouts** (13 variações)

Salas normais com escada. Podem conter:
- Inimigos simples (slug, bird, spit)
- Diamantes e corações
- Obstáculos (sawblades, cannons)
- **Powerups especiais** (mist, magnet, invincible, metal)

Exemplos:
- `layout_simple_01` a `layout_simple_05` - Salas básicas
- `layout_saw` - Serrotes horizontais
- `layout_cannon` - Canhões que lançam player
- `layout_magnet` - Powerup de ímã + diamantes extras
- `layout_mist` - Powerup de névoa
- `layout_invincible` - Powerup de invencibilidade
- `layout_metal` - Powerup de metal (requer 3 corações)

#### 2. **Split Layouts** (4 variações)

Salas com piso no meio, **sem escada**. Player deve pular para subir.

Ocorrem a cada 5 salas (índices 5, 10, 15, 20...).

Exemplos:
- `layout_split` - Piso no meio básico
- `layout_split_01` - Piso no meio com plataforma
- `layout_split_bird` - Com pássaros voadores
- `layout_split_spike` - Spikes nas paredes laterais

### Escolha de Layout Aleatório

```gdscript
func _pick_random_layout(type: String):
    # 1. Duplica lista de layouts disponíveis
    var available = layouts[type].duplicate()

    # 2. FILTRAGEM: Remove layouts de powerups ativos
    if type == "simple":
        if GameManager.mist_mode_active:
            available.erase(layout_mist_scene)

        if GameManager.magnet_active:
            available.erase(layout_magnet_scene)

        if GameManager.invincible_mode_active:
            available.erase(layout_invincible_scene)

        # Metal requer 3 corações cheios
        if not GameManager.can_spawn_metal_potion():
            available.erase(layout_metal_scene)

    # 3. ANTI-REPETIÇÃO: Remove layouts recentes
    for recent in last_layouts:
        available.erase(recent)

    # 4. Escolhe aleatoriamente
    var chosen = available[randi() % available.size()]

    # 5. Registra para evitar repetição
    last_layouts.append(chosen)
    if last_layouts.size() > 2:
        last_layouts.pop_front()

    return chosen
```

---

## Rooms Split vs Simple

### Room Simple (Normal)

```
┌──────────────────────────┐
│                          │
│    🐌   💎   🐦          │ ← Enemies + collectibles
│                          │
├──────────────────────────┤
│                          │
│         ┃                │ ← Escada (ladder)
│         ┃                │
│         ┃    ❤️          │
└─────────┻────────────────┘
```

**Características:**
- Tem escada para subir
- Escada alterna entre esquerda (0) e direita (1)
- Layout escolhido do pool "simple"
- Ocorre na maioria das salas

### Room Split (Especial)

```
┌──────────────────────────┐
│                          │
│    🐦    🐦   🐦         │ ← Inimigos voadores
│                          │
│ ┌──────────────────────┐ │ ← Piso no meio
│ │                      │ │
│ └──────────────────────┘ │
│                          │
│         💎               │
└──────────────────────────┘
```

**Características:**
- **NÃO tem escada** - player deve pular
- Piso no meio da sala
- Layout escolhido do pool "split"
- Ocorre a cada 5 salas (5, 10, 15, 20...)
- Maior desafio

### Código de Determinação

```gdscript
# Em main.gd
if index > 0 and index % 5 == 0:
    is_split = true
    room.is_split_room = true
```

---

## Sistema de Filtragem de Powerups

### Por que Filtrar?

Evitar que múltiplos powerups do mesmo tipo apareçam enquanto o modo está ativo.

**Exemplo:**
- Player pega powerup de **Mist** (névoa ativa por 10s)
- Sistema **remove** `layout_mist` das opções
- Novas salas **não** terão mais powerups de mist
- Após 10s, mist desativa
- Layout de mist volta a aparecer

### Powerups Filtrados

| Powerup | Condição de Filtragem |
|---------|----------------------|
| **Mist** | `GameManager.mist_mode_active == true` |
| **Magnet** | `GameManager.magnet_active == true` |
| **Invincible** | `GameManager.invincible_mode_active == true` |
| **Metal** | `GameManager.can_spawn_metal_potion() == false`<br>(requer 3 corações + modo inativo) |

### Tripla Camada de Proteção

Cada powerup especial tem 3 níveis de verificação:

1. **RoomManager**: Filtra layout antes de escolher
   ```gdscript
   if GameManager.mist_mode_active:
       available.erase(layout_mist_scene)
   ```

2. **Layout Script**: Verifica antes de spawnar
   ```gdscript
   if not GameManager.can_spawn_mist():
       return  # Não spawna chest
   ```

3. **Powerup Auto-Hide**: Esconde se modo ativar
   ```gdscript
   GameManager.mist_mode_changed.connect(_on_mist_mode_changed)
   ```

---

## Gerenciamento Dinâmico

### Geração Procedural

```gdscript
func manage_rooms():
    var current_room = get_current_room_index()

    # 1. Gera salas à frente
    generate_rooms_ahead(current_room)

    # 2. Remove salas antigas
    cleanup_old_rooms(current_room)
```

### Cálculo da Sala Atual

```gdscript
func get_current_room_index() -> int:
    var player_y = player.global_position.y
    var base_y = SCREEN_HEIGHT - ROOM_HEIGHT  # 480

    # Quanto mais negativo Y, mais alto o player está
    var rooms_above = int((base_y - player_y) / ROOM_HEIGHT)

    return max(0, rooms_above)
```

**Exemplo:**
```
Player Y = 480  → Room 0
Player Y = 320  → Room 1
Player Y = 160  → Room 2
Player Y = 0    → Room 3
Player Y = -160 → Room 4
```

### Geração à Frente

```gdscript
func generate_rooms_ahead(current_room_index: int):
    # Mantém 5 salas à frente
    var target_room = current_room_index + ROOMS_AHEAD

    # Gera todas as salas até o alvo
    for i in range(highest_room_created + 1, target_room + 1):
        create_room(i)
```

**Exemplo:**
```
Player na Room 10
Target = 10 + 5 = 15
Gera Rooms 11, 12, 13, 14, 15 (se ainda não existirem)
```

### Limpeza de Salas Antigas

```gdscript
func cleanup_old_rooms(current_room_index: int):
    var threshold = current_room_index - CLEANUP_THRESHOLD

    # Remove salas mais de 10 posições abaixo
    for room in rooms:
        var room_index = int(room.name.split("_")[1])

        if room_index < threshold:
            room.queue_free()
            rooms.erase(room)
```

**Exemplo:**
```
Player na Room 20
Threshold = 20 - 10 = 10
Remove Rooms: 0, 1, 2, ..., 9
Mantém Rooms: 10 em diante
```

### Visualização do Sistema Dinâmico

```
Frame 1:                Frame 2:                Frame 3:
Player @ Room 5         Player @ Room 8         Player @ Room 11

Rooms 6-10 (ahead)      Rooms 9-13 (ahead)      Rooms 12-16 (ahead)
Room 5 (current)        Room 8 (current)        Room 11 (current)
Rooms 0-4 (behind)      Rooms 3-7 (behind)      Rooms 6-10 (behind)

                        Remove: Rooms 0-2       Remove: Rooms 3-5
```

---

## Exemplos Práticos

### Exemplo 1: Criação de Layout Simples

**Arquivo:** `layout_simple_01.gd`

```gdscript
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160

var slug_scene = preload("res://scenes/enemies/slug.tscn")
var diamond_scene = preload("res://scenes/prize/diamond.tscn")

func _ready():
    spawn_enemies()
    spawn_collectibles()
    create_room_entry_detector()

func spawn_enemies():
    # Slug na esquerda
    var slug1 = slug_scene.instantiate()
    slug1.position = Vector2(80, ROOM_HEIGHT - 20)
    add_child(slug1)

    # Slug na direita
    var slug2 = slug_scene.instantiate()
    slug2.position = Vector2(280, ROOM_HEIGHT - 20)
    add_child(slug2)

func spawn_collectibles():
    # Diamante no centro
    var diamond = diamond_scene.instantiate()
    diamond.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0)
    add_child(diamond)

func create_room_entry_detector():
    # Detecta quando player entra na sala
    var detector = Area2D.new()
    detector.collision_mask = 1
    # ... configura detector ...
    detector.body_entered.connect(_on_room_entered)

func _on_room_entered(body):
    if body.name == "Player":
        GameManager.add_room()  # Incrementa contador
```

### Exemplo 2: Layout Split com Spikes

**Arquivo:** `layout_split_spike.gd`

```gdscript
extends Node2D

var spike_scene = preload("res://scenes/obstacles/spike.tscn")
var spike_side = ""  # "left" ou "right"

func _ready():
    create_middle_floor()
    spawn_wall_spikes()

func spawn_wall_spikes():
    # Escolhe lado aleatoriamente
    spike_side = "left" if randf() > 0.5 else "right"

    # Preenche parede com spikes
    var num_spikes = int(ROOM_HEIGHT / 25.0)

    for i in range(num_spikes):
        var spike = spike_scene.instantiate()

        if spike_side == "left":
            spike.position = Vector2(16, i * 25 + 12)
            spike.flip_h = false  # Aponta para direita
        else:
            spike.position = Vector2(344, i * 25 + 12)
            spike.flip_h = true   # Aponta para esquerda

        add_child(spike)
```

### Exemplo 3: Layout com Powerup Especial

**Arquivo:** `layout_metal.gd`

```gdscript
extends Node2D

var chest_scene = preload("res://scenes/obstacles/chest.tscn")

func _ready():
    spawn_metal_chest()

func spawn_metal_chest():
    # VERIFICAÇÃO: Requer 3 corações cheios
    if not GameManager.can_spawn_metal_potion():
        print("🛡️ Metal não spawnou: requisitos não atendidos")
        return

    var chest = chest_scene.instantiate()
    chest.powerup_type = "metal"
    chest.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 25)
    add_child(chest)
```

### Exemplo 4: Debugging do Sistema

```gdscript
# Em main.gd
func _process(delta):
    # Pressione SELECT para debug
    if Input.is_action_just_pressed("ui_select"):
        print("=== DEBUG ROOMS ===")
        print("Total rooms ativas: ", rooms.size())
        print("Sala mais alta: ", highest_room_created)
        print("Player na sala: ", get_current_room_index())
        print("Rooms em memória: ", rooms.map(func(r): return r.name))
```

**Output Exemplo:**
```
=== DEBUG ROOMS ===
Total rooms ativas: 8
Sala mais alta: 15
Player na sala: 10
Rooms em memória: [Room_8, Room_9, Room_10, Room_11, Room_12, Room_13, Room_14, Room_15]
```

---

## Diagrama Completo do Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                        main.gd                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ _ready()                                             │   │
│  │  ├─> GameManager.reset()                            │   │
│  │  ├─> create_rooms() [Cria 5 iniciais]               │   │
│  │  └─> find_player()                                   │   │
│  │                                                       │   │
│  │ _process(delta)                                      │   │
│  │  └─> manage_rooms()                                  │   │
│  │       ├─> get_current_room_index()                   │   │
│  │       ├─> generate_rooms_ahead()                     │   │
│  │       └─> cleanup_old_rooms()                        │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────────┘
                        │ chama
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   room_manager.gd                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ populate_room(room, index)                           │   │
│  │  ├─> Se index == 0: VAZIA                            │   │
│  │  ├─> Se room.is_split_room: tipo = "split"          │   │
│  │  │    Senão: tipo = "simple"                         │   │
│  │  └─> _pick_random_layout(tipo)                       │   │
│  │       ├─> Filtra powerups ativos                     │   │
│  │       ├─> Remove layouts recentes                    │   │
│  │       └─> Escolhe aleatoriamente                     │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────────┘
                        │ instancia
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                  Layout Individual                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ layout_simple_01.gd / layout_split_spike.gd / etc.  │   │
│  │  ├─> _ready()                                        │   │
│  │  ├─> spawn_enemies()                                 │   │
│  │  ├─> spawn_collectibles()                            │   │
│  │  ├─> spawn_obstacles()                               │   │
│  │  ├─> spawn_powerups() [com verificações]            │   │
│  │  └─> create_room_entry_detector()                   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Resumo - Pontos Chave

1. **Geração Infinita**: Salas são criadas dinamicamente enquanto o player sobe
2. **Limpeza Automática**: Salas antigas são removidas para economizar memória
3. **Duas Categorias**: Layouts "simple" (com escada) e "split" (sem escada)
4. **Sistema de Filtragem**: Powerups não aparecem se seus modos estão ativos
5. **Anti-Repetição**: Últimas 2 salas não se repetem
6. **Split Rooms**: A cada 5 salas, sala especial sem escada
7. **Room 0 Especial**: Primeira sala é sempre vazia (ponto de spawn)

---

## Adicionando um Novo Layout

### Passo a Passo

1. **Criar script do layout**
   ```gdscript
   # scenes/room_layouts/layout_custom.gd
   extends Node2D

   func _ready():
       spawn_content()
       create_room_entry_detector()
   ```

2. **Criar cena do layout**
   - File → New Scene
   - Root: Node2D
   - Attach script: `layout_custom.gd`
   - Save como: `layout_custom.tscn`

3. **Registrar no RoomManager**
   ```gdscript
   # room_manager.gd
   var layouts = {
       "simple": [
           # ... outros layouts ...
           preload("res://scenes/room_layouts/layout_custom.tscn")
       ]
   }
   ```

4. **Testar**
   - Execute o jogo
   - Suba algumas salas
   - Seu layout aparecerá aleatoriamente

---

**Documento criado em:** 2026-01-01
**Última atualização:** Sistema de chest implementado
