# Development Log - High Up

## 2025-12-24

### Major Feature: Invincible Mode System

#### Overview
Implemented a complete invincible mode powerup system - the ultimate protection powerup that provides immunity to both enemies and obstacles.

#### Core Features
- **Duration**: 10 seconds of complete invincibility
- **Enemy Immunity**: Player liberates animals on contact (same as metal mode)
- **Obstacle Immunity**: No damage from spikes, sawblades, or projectiles
- **Visual Effects**: Golden tint + sparkle particle trail
- **UI Indicator**: Golden progress bar showing remaining time
- **Auto-Hide System**: Powerup icons hide when mode is already active

#### Files Created
1. `scenes/powerups/invincible.gd` - Invincible powerup script with auto-hide
2. `scenes/powerups/invincible.tscn` - Invincible powerup scene
3. `scenes/room_layouts/layout_invincible.gd` - Room layout for spawning powerup
4. `scenes/room_layouts/layout_invincible.tscn` - Room scene
5. `scenes/ui/invincible_indicator.gd` - Progress bar UI script
6. `scenes/ui/invincible_indicator.tscn` - Progress bar UI scene

#### GameManager Changes
Added comprehensive invincible mode management:
```gdscript
signal invincible_mode_changed(is_active: bool)
var invincible_mode_active = false
var invincible_timer: Timer = null
const INVINCIBLE_DURATION = 10.0

func can_spawn_invincible() -> bool
func activate_invincible_mode()
func deactivate_invincible_mode()
func get_invincible_progress() -> float
```

#### Player Visual Effects
**Initial Approach (Removed):**
- Attempted 1.5x scale increase
- Caused physics bugs (player floating, small sprite)
- Added complexity with `original_sprite_scale` tracking

**Final Solution:**
- Removed all scale modifications
- Implemented `GPUParticles2D` sparkle trail system:
  - 30 particles with 0.6s lifetime
  - Golden color (1.0, 0.85, 0.0)
  - Backward direction trail
  - Fade-out gradient
  - Gravity-affected particles
- Golden modulate color (2.0, 1.5, 0.2)

File: `scripts/player.gd`

#### Enemy Modifications
Updated all enemies to liberate on contact with invincible player:
- `scenes/enemies/slug.gd`
- `scenes/enemies/bird.gd`
- `scenes/enemies/spit.gd`

```gdscript
if GameManager.metal_mode_active or GameManager.invincible_mode_active:
    be_freed()
    return
```

#### Obstacle Modifications
Added immunity checks to all obstacles:
- `scenes/obstacles/spike.gd`
- `scenes/obstacles/sawblade.gd`
- `scenes/obstacles/sawblade_horizontal.gd`

```gdscript
if GameManager.invincible_mode_active:
    return  # No damage
```

#### RoomManager Integration
Added invincible layout to room pool and filtering system:
```gdscript
var layout_invincible_scene = preload("res://scenes/room_layouts/layout_invincible.tscn")

# Prevents spawning invincible rooms when mode already active
if GameManager.invincible_mode_active and layout_invincible_scene in available:
    available.erase(layout_invincible_scene)
```

File: `scripts/room_manager.gd`

---

### Feature: Magnet Mode Protection System

#### Problem
Magnet powerups could spawn while magnet mode was already active, and multiple magnets could exist simultaneously.

#### Solution
Applied the same three-layer protection system used by mist mode:

1. **GameManager Layer**:
```gdscript
signal magnet_mode_changed(is_active: bool)
var magnet_active = false

func can_spawn_magnet() -> bool:
    if magnet_active:
        return false
    return true

func activate_magnet_mode()
func deactivate_magnet_mode()
```

2. **RoomManager Layer**:
```gdscript
if GameManager.magnet_active and layout_magnet_scene in available:
    available.erase(layout_magnet_scene)
```

3. **Powerup Auto-Hide Layer**:
```gdscript
GameManager.magnet_mode_changed.connect(_on_magnet_mode_changed)

func _on_magnet_mode_changed(is_active: bool):
    if is_active:
        visible = false
        collision_layer = 0
        collision_mask = 0
```

#### Files Modified
- `scripts/game_manager.gd` - Added magnet mode state management
- `scripts/player.gd` - Updated to use GameManager instead of local variable
- `scenes/powerups/magnet.gd` - Added auto-hide behavior
- `scenes/room_layouts/layout_magnet.gd` - Added spawn check
- `scripts/room_manager.gd` - Added filtering logic

---

### Bug Fixes

#### Bug #1: Spit Projectile Ignoring Invincible Mode
**Issue**: Player could be killed by spit projectiles even in invincible mode.

**Root Cause**: `spit_projectile.gd` checked player's invulnerability flags but not `GameManager.invincible_mode_active`.

**Fix**: Added invincible mode check in collision handler:
```gdscript
if GameManager.invincible_mode_active:
    print("💧 Projétil ignorou player invencível!")
    queue_free()
    return
```

File: `scenes/enemies/spit_projectile.gd:42-46`

#### Bug #2: Special Powerups Being Attracted by Magnet
**Issue**: Invincible, mist, magnet, and metal potion powerups were following the player horizontally when magnet mode was active.

**Root Cause**: All special powerups were incorrectly added to the "collectible" group, making them targets for magnet attraction. The attraction code (`move_toward()`) was working correctly in both X and Y, but these powerups shouldn't be attracted at all.

**Fix**: Removed `add_to_group("collectible")` from all special powerup scripts:
```gdscript
# Before
add_to_group("collectible")  # Para o magnet funcionar

# After
# NÃO adiciona ao grupo collectible - powerups especiais não devem ser atraídos
```

**Files Modified**:
- `scenes/powerups/metal_potion.gd`
- `scenes/powerups/magnet.gd`
- `scenes/powerups/invincible.gd`
- `scenes/powerups/mist.gd`

**Note**: Only diamonds and hearts should be in the "collectible" group.

---

### HUD Updates

Added invincible mode indicator to the HUD:
```gdscript
var invincible_indicator: Control = null
var invincible_indicator_scene = preload("res://scenes/ui/invincible_indicator.tscn")

invincible_indicator = invincible_indicator_scene.instantiate()
invincible_indicator.position = Vector2(80, 40)  # Below mist indicator
add_child(invincible_indicator)
```

File: `scenes/ui/hud.gd`

---

### Architecture Patterns

#### Triple-Layer Protection System
All special powerups now follow this consistent pattern:

1. **GameManager State**: Central boolean + signal system
2. **RoomManager Filtering**: Prevents spawning rooms with active powerups
3. **Powerup Auto-Hide**: Individual powerups hide when mode activates elsewhere

This ensures:
- No duplicate powerups can be collected
- Visual consistency (hidden powerups don't confuse players)
- Clean separation of concerns

#### Signal-Based Communication
All mode changes emit signals that components can listen to:
- `magnet_mode_changed(is_active: bool)`
- `invincible_mode_changed(is_active: bool)`
- `mist_mode_changed(is_active: bool)`

Benefits:
- Decoupled components
- Easy to add new listeners
- No tight coupling between systems

---

### Testing Status
- ✅ Invincible mode: Full immunity to all damage sources
- ✅ Invincible mode: Visual effects (golden tint + sparkles) working
- ✅ Invincible mode: Progress bar displays correctly
- ✅ Invincible mode: Auto-disables after 10 seconds
- ✅ Spit projectiles: Destroy on contact with invincible player
- ✅ Magnet mode: Protection system prevents duplicate spawns
- ✅ Special powerups: No longer attracted by magnet mode
- ✅ All powerups: Auto-hide when their mode is already active

---

### Lessons Learned
- Simple particle systems are often better than complex scale animations
- Physics modifications (scale changes) can have unexpected side effects
- Group-based entity categorization requires careful management
- Consistent architectural patterns across similar features improve maintainability
- Triple-layer protection (state + filtering + auto-hide) is robust and reliable

---

**Session Impact**: Added ultimate invincible powerup, fixed critical bugs, established consistent protection patterns across all special powerups.

## 2025-12-11

### Bug Fixes
- **Game Over UI crash fixed**: Corrected node name mismatch in `game_over.gd` - was referencing `SpitsSavedLabel` but scene had `SpitsSavedLabel2`
  - File: `scenes/ui/game_over.gd:9`
  - Impact: Game no longer crashes when showing final stats

### Major Refactoring: Enemy Collision System Overhaul

#### Problem Identified
- Spit enemy was frequently getting "stuck" on player's head when player was launched upward by cannons
- Player could get crushed/trapped between enemies and walls
- Similar issues occurred occasionally with Bird and Slug enemies
- Multiple attempted solutions failed:
  1. Dynamically changing `collision_layer` - enemies still interacted physically
  2. Disabling `CollisionShape2D` temporarily - caused Spits to fall through floors
  3. Using `StaticBody2D` - still blocked player movement

#### Solution Implemented
**Complete architectural change**: Migrated all enemies from `CharacterBody2D` to `Node2D` with manual movement

**New Enemy Architecture:**
- Root: `Node2D` (purely visual, no physics)
- Visual: `AnimatedSprite2D`
- Damage Detection: `HitBox` (Area2D) - detects player but doesn't block movement
- Floor/Wall Detection: `RayCast2D` nodes for ground enemies

#### Enemies Refactored

**1. Spit (Stationary Ground Enemy)**
- Changed from `CharacterBody2D` to `Node2D`
- Removed physical collision completely
- Added `FloorDetector` (RayCast2D) to position on ground at spawn
- No movement needed - stays in place
- File: `scenes/enemies/spit.tscn`, `scenes/enemies/spit.gd`

**2. Bird (Flying Enemy)**
- Changed from `CharacterBody2D` to `Node2D`
- Removed `velocity` + `move_and_slide()` system
- Implemented manual horizontal movement: `global_position.x += direction * speed * delta`
- Kept boundary checking for direction reversal
- Maintained random speed selection (MEDIUM, FAST, ULTRA_FAST)
- File: `scenes/enemies/bird.tscn`, `scenes/enemies/bird.gd`

**3. Slug (Ground Walking Enemy)**
- Changed from `CharacterBody2D` to `Node2D`
- Added `FloorDetector` (RayCast2D) - detects ground below
- Added `WallDetector` (RayCast2D) - detects walls ahead
- Implemented manual gravity simulation with `vertical_velocity`
- Snaps to floor using raycast collision point
- Dynamically updates wall detector direction based on movement
- File: `scenes/enemies/slug.tscn`, `scenes/enemies/slug.gd`

### What Was Preserved
All enemies maintain their original behavior:
- ✅ Damage detection works identically
- ✅ Ignore player when `is_launched = true`
- ✅ Liberation effects (metal mode) unchanged
- ✅ Movement patterns identical to before
- ✅ Random speed/direction initialization preserved
- ✅ Sprite flipping based on direction
- ✅ Game Manager integration (animal tracking)

### Benefits Achieved
- **Zero collision bugs**: Player passes through enemies without getting stuck
- **No crushing**: Impossible to trap player between enemy and wall
- **Simpler code**: Manual movement is more predictable than physics engine
- **Better performance**: `Node2D` is lighter than `CharacterBody2D`
- **Consistent pattern**: All enemies follow same architecture

### Documentation Added
- Created `ENEMY_DESIGN_PATTERN.md` - comprehensive tutorial explaining:
  - Why `CharacterBody2D` causes problems
  - New `Node2D` + `Area2D` architecture
  - Implementation guide for each enemy type
  - Code examples for flying, walking, and stationary enemies
  - Migration checklist from old to new system
  - Testing guidelines

### Technical Details

**Key Code Changes:**

*Movement (Before → After):*
```gdscript
# Before (CharacterBody2D)
velocity.x = direction * speed
move_and_slide()

# After (Node2D)
global_position.x += direction * speed * delta
```

*Floor Detection (Before → After):*
```gdscript
# Before (CharacterBody2D)
if is_on_floor():
    velocity.y = 0

# After (Node2D + RayCast)
if floor_detector.is_colliding():
    var collision_point = floor_detector.get_collision_point()
    global_position.y = collision_point.y - 9
```

*Wall Detection (Before → After):*
```gdscript
# Before (CharacterBody2D)
if is_on_wall():
    direction *= -1

# After (Node2D + RayCast)
if wall_detector.is_colliding():
    direction *= -1
    wall_detector.target_position = Vector2(15 * direction, 0)
```

### Files Modified Today
1. `scenes/ui/game_over.gd` - Fixed Spit label reference
2. `scenes/enemies/spit.tscn` - Restructured to Node2D
3. `scenes/enemies/spit.gd` - Removed physics, added floor detection
4. `scenes/enemies/bird.tscn` - Restructured to Node2D
5. `scenes/enemies/bird.gd` - Implemented manual movement
6. `scenes/enemies/slug.tscn` - Restructured to Node2D, added RayCasts
7. `scenes/enemies/slug.gd` - Manual gravity + movement with raycasts

### Files Created Today
1. `ENEMY_DESIGN_PATTERN.md` - Enemy design tutorial/reference
2. `DEVLOG.md` - This development log

### Testing Status
- ✅ Spit: No longer gets stuck on player's head
- ✅ Bird: Flies smoothly, player passes through
- ✅ Slug: Walks on ground, detects walls, no collision bugs
- ✅ All enemies: Damage detection works correctly
- ✅ All enemies: Liberation effects work correctly
- ✅ Game Over screen: Shows all animal counts including Spits

### Lessons Learned
- Physics engines can introduce unpredictable behavior in specific scenarios
- Sometimes the best solution is to avoid the physics engine entirely
- Manual movement gives complete control and predictability
- `RayCast2D` is excellent for custom ground/wall detection
- `Area2D` is perfect for damage detection without physical blocking
- Consistent patterns across similar entities (enemies) makes code more maintainable

### Next Steps (Future Considerations)
- Monitor for any edge cases with new enemy system
- Consider applying same pattern to any future enemy types
- Possible optimization: pool enemies instead of creating/destroying

---

**Total Session Impact**: Eliminated entire class of collision bugs, improved code architecture, documented pattern for future development.
