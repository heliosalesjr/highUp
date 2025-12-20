# Room System Design - High Up

## Overview

High Up uses a modular room system with procedural generation. The game generates rooms dynamically as the player climbs, creating an infinite vertical experience.

## Architecture

### Core Components

```
┌─────────────────────────────────────────┐
│ Main (main.gd)                          │
│ - Manages room creation/destruction     │
│ - Tracks player position                │
│ - Handles procedural generation         │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ RoomManager (room_manager.gd)          │
│ - Stores layout templates               │
│ - Selects random layouts                │
│ - Prevents repetition                   │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ Room (room.gd + room.tscn)             │
│ - Base room structure                   │
│ - Floor, walls, ladder                  │
│ - Container for layouts                 │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ Layout (layout_*.gd + layout_*.tscn)   │
│ - Obstacles, enemies, prizes            │
│ - Room-specific logic                  │
│ - Spawn patterns                        │
└─────────────────────────────────────────┘
```

## Design Patterns

### 1. Composition Pattern

**Base Room** (container) + **Layout** (content)

```
Room (empty structure)
  ├─ Floor (always present)
  ├─ Walls (always present)
  ├─ Ladder (conditional)
  └─ Layout (dynamically added)
       ├─ Obstacles
       ├─ Enemies
       └─ Prizes
```

**Why this pattern?**
- Separates structure from content
- Reusable base room
- Unlimited layout variations
- Easy to test individual layouts

### 2. Template Method Pattern

All layouts inherit from `Node2D` and follow the same structure:

```gdscript
func _ready():
    create_obstacles()
    spawn_enemies()
    spawn_prizes()
    create_detectors()
```

Each layout implements these methods differently, but the flow is consistent.

### 3. Strategy Pattern

The `RoomManager` uses different strategies for room selection:

- **Simple Rooms**: Random selection with anti-repetition
- **Split Rooms**: Triggered at specific intervals (every 5th room)

## Room Types

### Normal Rooms

**Characteristics:**
- Single floor at the bottom
- Ladder on left OR right side
- Full width: 360px
- Height: 160px

**Example: `layout_simple_01.gd`**
```gdscript
func _ready():
    create_enemies()      # Spawns slugs
    create_room_entry_detector()
```

### Split Rooms

**Characteristics:**
- Two floors (ground + middle platform)
- NO ladder (jump required)
- Middle floor at 50% height
- Rewards player with +2 room count

**Variations:**

| Layout | Description | Middle Floor Width |
|--------|-------------|-------------------|
| `layout_split` | Basic split room | Full width (348px) |
| `layout_split_01` | Small platform | 1/3 width (120px) |
| `layout_split_bird` | Birds flying | Full width (348px) |
| `layout_split_spike` | Wall spikes | Full width (348px) |

**Example: `layout_split.gd`**
```gdscript
func _ready():
    create_middle_floor()           # Platform at 50% height
    spawn_prize_randomly()          # Prize on top
    create_room_entry_detector()    # +1 on entry
    create_second_floor_detector()  # +1 on reaching middle
```

## Room Generation Flow

### 1. Initial Spawn

```gdscript
# main.gd
const INITIAL_ROOMS = 5

func _ready():
    create_rooms()  # Creates 5 initial rooms
```

### 2. Procedural Generation

```gdscript
# main.gd - Runs every frame
func manage_rooms():
    var current_room = get_current_room_index()

    # Generate rooms ahead
    generate_rooms_ahead(current_room)

    # Remove old rooms behind
    cleanup_old_rooms(current_room)
```

### 3. Layout Selection

```gdscript
# room_manager.gd
func populate_room(room: Node2D, room_index: int):
    # Room 0 is always empty
    if room_index == 0:
        return

    # Every 5th room is a split room
    var layout_type = "split" if room.is_split_room else "simple"

    # Pick random layout (with anti-repetition)
    var layout = _pick_random_layout(layout_type)

    # Add to room
    room.add_child(layout.instantiate())
```

### 4. Anti-Repetition System

```gdscript
var last_layouts = []
const MAX_RECENT = 2

func _pick_random_layout(type: String):
    var available = layouts[type].duplicate()

    # Remove recently used layouts
    for recent in last_layouts:
        if recent in available:
            available.erase(recent)

    # Pick random from remaining
    var chosen = available[randi() % available.size()]

    # Track usage
    last_layouts.append(chosen)
    if last_layouts.size() > MAX_RECENT:
        last_layouts.pop_front()

    return chosen
```

## Room Coordinates

### World Space

Rooms are positioned vertically in world coordinates:

```
Y Position = (SCREEN_HEIGHT - ROOM_HEIGHT) - (index * ROOM_HEIGHT)

Where:
- SCREEN_HEIGHT = 640px
- ROOM_HEIGHT = 160px
- index = room number (0, 1, 2, ...)

Example:
Room 0: Y = (640 - 160) - (0 * 160) = 480
Room 1: Y = (640 - 160) - (1 * 160) = 320
Room 2: Y = (640 - 160) - (2 * 160) = 160
Room 3: Y = (640 - 160) - (3 * 160) = 0
Room 4: Y = (640 - 160) - (4 * 160) = -160
...
```

**Negative Y = Higher position** (player climbs towards negative Y)

### Local Space

Inside each room, coordinates are relative:

```
┌─────────────────────────────────────────┐ Y = 0 (top)
│                                         │
│         Room Local Coordinates          │
│                                         │
│         (0,0) = Top-left corner         │
│                                         │
│                                         │
└─────────────────────────────────────────┘ Y = 160 (bottom)
X = 0                                X = 360
```

## Room Lifecycle

### Creation

```
1. Main calls create_room(index)
2. Room instance created from room.tscn
3. Room positioned in world space
4. RoomManager.populate_room() called
5. Random layout selected and added
6. Layout's _ready() executes
   ├─ Spawns obstacles
   ├─ Spawns enemies
   ├─ Spawns prizes
   └─ Creates detectors
```

### Cleanup

```
1. Player climbs higher
2. manage_rooms() checks distance
3. If room is > CLEANUP_THRESHOLD behind player:
   ├─ room.queue_free()
   └─ Remove from rooms array
```

**Constants:**
- `CLEANUP_THRESHOLD = 10` (removes rooms 10+ below player)
- `ROOMS_AHEAD = 5` (generates 5 rooms ahead)

## Creating New Layouts

### Step 1: Create Script

```gdscript
# layout_my_custom.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160

func _ready():
    spawn_my_content()
    create_room_entry_detector()

func spawn_my_content():
    # Your custom logic here
    pass

func create_room_entry_detector():
    # Standard detector (copy from other layouts)
    var detector = Area2D.new()
    detector.name = "EntryDetector"
    detector.collision_layer = 0
    detector.collision_mask = 1

    var collision = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(ROOM_WIDTH, 40)
    collision.shape = shape
    collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 20)

    detector.add_child(collision)
    detector.body_entered.connect(_on_room_entered)
    add_child(detector)

func _on_room_entered(body):
    if body.name == "Player":
        GameManager.add_room()
        get_node("EntryDetector").queue_free()
```

### Step 2: Create Scene

```
# layout_my_custom.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/room_layouts/layout_my_custom.gd" id="1"]

[node name="LayoutMyCustom" type="Node2D"]
script = ExtResource("1")
```

### Step 3: Register in RoomManager

```gdscript
# room_manager.gd
var layouts = {
    "simple": [
        # ... existing layouts ...
        preload("res://scenes/room_layouts/layout_my_custom.tscn")  # ← ADD HERE
    ],
    "split": [
        # ... split layouts ...
    ]
}
```

### Step 4: Test

Run the game and your layout will appear randomly in the rotation!

## Common Patterns

### Spawning Obstacles

```gdscript
var obstacle_scene = preload("res://scenes/obstacles/my_obstacle.tscn")

func spawn_obstacle():
    var obstacle = obstacle_scene.instantiate()
    obstacle.position = Vector2(100, 50)  # Local coordinates
    add_child(obstacle)
```

### Spawning Enemies

```gdscript
var enemy_scene = preload("res://scenes/enemies/slug.tscn")

func spawn_enemies():
    for i in range(3):
        var enemy = enemy_scene.instantiate()
        enemy.position = Vector2(i * 100 + 50, ROOM_HEIGHT - 30)
        add_child(enemy)
```

### Random Spawning

```gdscript
func spawn_prize_randomly():
    if randf() > 0.5:  # 50% chance
        return

    var prize_position = Vector2(ROOM_WIDTH / 2.0, 40)

    if GameManager.can_spawn_heart():
        var heart = heart_scene.instantiate()
        heart.position = prize_position
        add_child(heart)
```

### Floor Creation (Split Rooms)

```gdscript
func create_middle_floor():
    var middle_floor = StaticBody2D.new()

    var collision = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(ROOM_WIDTH - 12, 1)  # -12 for walls
    collision.shape = shape
    collision.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0)
    collision.one_way_collision = true

    middle_floor.add_child(collision)
    add_child(middle_floor)
```

## Best Practices

### 1. Always Use Constants

```gdscript
const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160
const WALL_THICKNESS = 6

# DON'T hardcode values
var pos = Vector2(360, 160)  # ❌

# DO use constants
var pos = Vector2(ROOM_WIDTH, ROOM_HEIGHT)  # ✅
```

### 2. Clean Up Detectors

```gdscript
func _on_room_entered(body):
    if body.name == "Player":
        GameManager.add_room()
        get_node("EntryDetector").queue_free()  # ← IMPORTANT!
```

Detectors should self-destruct after triggering to prevent multiple counts.

### 3. Check GameManager State

```gdscript
# For hearts
if GameManager.can_spawn_heart():
    spawn_heart()

# For metal potions
if GameManager.can_spawn_metal_potion():
    spawn_potion()
```

### 4. Use Local Coordinates

All positions inside layouts should be **relative to the room**, not world space.

```gdscript
# Room is at world Y = -320
# But inside the layout:
enemy.position = Vector2(100, 50)  # ✅ Local to room
enemy.position = Vector2(100, -270)  # ❌ World coordinates
```

### 5. Preload Scenes at Top

```gdscript
# ✅ GOOD - Load once at script load
var enemy_scene = preload("res://scenes/enemies/slug.tscn")

func spawn_enemy():
    var enemy = enemy_scene.instantiate()

# ❌ BAD - Loads every time function is called
func spawn_enemy():
    var enemy = load("res://scenes/enemies/slug.tscn").instantiate()
```

## Files Reference

### Core System
- `scripts/main.gd` - Room generation manager
- `scripts/room_manager.gd` - Layout selector
- `scripts/room.gd` - Base room logic
- `scenes/room.tscn` - Base room structure

### Simple Layouts
- `layout_simple_01.gd` - Slug enemy
- `layout_simple_02.gd` - Double slugs
- `layout_simple_03.gd` - Slug with invisible floor
- `layout_simple_04.gd` - Triple slugs
- `layout_simple_05.gd` - No enemies (empty)
- `layout_saw.gd` - Sawblade corners
- `layout_saw_floor.gd` - Sawblade on floor
- `layout_cannon.gd` - Cannon launcher
- `layout_magnet.gd` - Magnet powerup
- `layout_spit.gd` - Spit enemy

### Split Layouts
- `layout_split.gd` - Basic split (full width platform)
- `layout_split_01.gd` - Small platform (1/3 width)
- `layout_split_bird.gd` - Birds flying
- `layout_split_spike.gd` - Wall spikes

## Debugging

### View Room Count
```gdscript
# In main.gd
print("Total rooms: ", rooms.size())
print("Highest room: ", highest_room_created)
```

### Check Current Room
```gdscript
# In main.gd
var current = get_current_room_index()
print("Player in room ~", current)
```

### Visualize Rooms
Add labels in `_ready()` for debugging:
```gdscript
func create_label(text: String):
    var label = Label.new()
    label.text = text
    label.position = Vector2(ROOM_WIDTH / 2.0 - 60, 20)
    add_child(label)
```

## Performance Considerations

### Room Cleanup
- Old rooms are automatically destroyed
- Keeps memory usage constant
- Maintains 60 FPS even after hours of play

### Preloading
- All layouts are preloaded at startup
- No loading stutter during gameplay
- Instant room instantiation

### Object Pooling
Currently not implemented, but could be added for:
- Common enemies (slug)
- Projectiles
- Visual effects

## Future Enhancements

Potential improvements to the room system:

1. **Room Themes**
   - Forest rooms (current)
   - Cave rooms
   - Sky rooms
   - Dynamic theme transitions

2. **Difficulty Scaling**
   - More enemies at higher rooms
   - Faster obstacles
   - Complex layouts

3. **Special Rooms**
   - Boss rooms every 50 rooms
   - Shop rooms
   - Checkpoint rooms

4. **Procedural Layout Generation**
   - Generate layouts algorithmically
   - Endless unique combinations
   - Seed-based generation

5. **Room Modifiers**
   - Low gravity rooms
   - Speed boost rooms
   - Inverted controls rooms
