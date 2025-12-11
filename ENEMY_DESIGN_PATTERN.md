# Enemy Design Pattern - Collision-Free Approach

## Overview

This document describes our approach to creating enemies in Godot that **never cause collision bugs** with the player. This pattern eliminates common issues like enemies getting "stuck" on the player's head, crushing the player between walls, or creating physics glitches during high-speed collisions.

## The Problem with CharacterBody2D

### Why CharacterBody2D Causes Issues

When both the player and enemies use `CharacterBody2D`, several problems occur:

1. **Physics Pushing**: Two `CharacterBody2D` nodes colliding at high speeds can push each other in unpredictable ways
2. **Stuck/Glued Entities**: Enemies can get "glued" to the player, especially when the player is launched upward by cannons
3. **Crushing Bugs**: Player can get trapped between an enemy and a wall, causing strange physics behavior
4. **Complex Edge Cases**: Disabling collisions conditionally (e.g., when player is launched) doesn't fully solve the problem

### Failed Approaches We Tried

1. ❌ **Changing collision_layer dynamically** - Enemies still interact physically
2. ❌ **Disabling CollisionShape2D temporarily** - Caused enemies to fall through floors
3. ❌ **Using StaticBody2D** - Still blocked player movement, causing crushing bugs

## The Solution: Node2D + Area2D

### Core Concept

**Enemies should be purely visual entities that only *detect* the player, never *block* them.**

### Architecture

```
Enemy (Node2D)                    ← Root: no physics, purely visual
├── AnimatedSprite2D              ← Visual representation
├── HitBox (Area2D)               ← Detects player (damage zone)
│   └── CollisionShape2D          ← Detection area
├── FloorDetector (RayCast2D)     ← (Optional) Finds floor
└── WallDetector (RayCast2D)      ← (Optional) Detects walls
```

### Why This Works

✅ **No Physical Collision**: Enemy is `Node2D`, so it never blocks anything
✅ **Damage Still Works**: `Area2D` HitBox detects when player touches enemy
✅ **Manual Control**: We control all movement via code, no physics engine surprises
✅ **Zero Edge Cases**: No need to disable collisions conditionally

## Implementation Guide

### Step 1: Create the Scene Structure

```gdscript
# Remove CharacterBody2D, use Node2D instead
[node name="Enemy" type="Node2D"]

# Visual representation
[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]

# Damage detection ONLY (not physical collision)
[node name="HitBox" type="Area2D" parent="."]
collision_layer = 8      # Enemy layer
collision_mask = 1       # Detects player layer

# For enemies that need floor detection
[node name="FloorDetector" type="RayCast2D" parent="."]
target_position = Vector2(0, 20)
collision_mask = 1       # Detects floor/walls

# For enemies that need wall detection
[node name="WallDetector" type="RayCast2D" parent="."]
target_position = Vector2(15, 0)
collision_mask = 1       # Detects floor/walls
```

### Step 2: Implement Manual Movement

#### Flying Enemy (Bird Example)

```gdscript
extends Node2D

var speed = 150.0
var direction = -1

func _process(delta):
    if is_being_freed:
        return

    # Manual horizontal movement (no physics)
    global_position.x += direction * speed * delta

    # Check boundaries and reverse
    if global_position.x <= 5 or global_position.x >= 355:
        direction *= -1
```

#### Ground Enemy with Gravity (Slug Example)

```gdscript
extends Node2D

var speed = 50.0
var direction = 1
var vertical_velocity = 0.0
const GRAVITY = 980.0

@onready var floor_detector = $FloorDetector
@onready var wall_detector = $WallDetector

func _process(delta):
    if is_being_freed:
        return

    # Update raycasts
    floor_detector.force_raycast_update()
    wall_detector.force_raycast_update()

    # Manual gravity simulation
    if not floor_detector.is_colliding():
        vertical_velocity += GRAVITY * delta
        global_position.y += vertical_velocity * delta
    else:
        # Snap to floor
        vertical_velocity = 0
        var collision_point = floor_detector.get_collision_point()
        global_position.y = collision_point.y - 9  # Adjust to sprite height

    # Horizontal movement
    global_position.x += direction * speed * delta

    # Wall detection and direction change
    if wall_detector.is_colliding():
        direction *= -1
        wall_detector.target_position = Vector2(15 * direction, 0)
```

#### Stationary Enemy (Spit/Frog Example)

```gdscript
extends Node2D

@onready var floor_detector = $FloorDetector

func _ready():
    snap_to_floor()

func snap_to_floor():
    """Position enemy on floor using raycast"""
    if not floor_detector:
        return

    floor_detector.force_raycast_update()

    if floor_detector.is_colliding():
        var collision_point = floor_detector.get_collision_point()
        global_position.y = collision_point.y - 13  # Half of sprite height
```

### Step 3: Implement Damage Detection

```gdscript
@onready var hitbox = $HitBox

func _ready():
    if hitbox:
        hitbox.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    """Detects player collision"""
    if body.name == "Player" and body.has_method("take_damage"):
        # Ignore if player is launched (invulnerable)
        if body.is_launched:
            return

        # Player in metal mode destroys enemy
        if GameManager.metal_mode_active:
            be_freed()
            return

        # Normal damage
        body.take_damage(self)
```

### Step 4: Handle Enemy Destruction

```gdscript
var is_being_freed = false

func be_freed():
    """Called when enemy is destroyed (e.g., metal mode)"""
    if is_being_freed:
        return

    is_being_freed = true

    # Notify game manager
    GameManager.free_animal("EnemyName")

    # Disable hitbox (no more damage)
    if hitbox:
        hitbox.collision_mask = 0
        hitbox.collision_layer = 0

    # Play liberation effect
    liberation_effect()

func liberation_effect():
    """Visual effect when enemy is freed"""
    var tween = create_tween()

    # Golden glow
    tween.tween_property(animated_sprite, "modulate", Color(2.0, 2.0, 1.0), 0.3)

    # Escape animation (fly/run away)
    tween.tween_property(self, "global_position:y", global_position.y - 100, 1.0)

    # Remove when done
    tween.finished.connect(queue_free)
```

## Benefits of This Approach

### For Development

✅ **Predictable**: All movement is manual, no physics engine surprises
✅ **Debuggable**: Easy to understand what's happening at any moment
✅ **Maintainable**: Simple code structure, no complex edge cases
✅ **Flexible**: Easy to add new enemy types following the same pattern

### For Gameplay

✅ **No Collision Bugs**: Player never gets stuck on enemies
✅ **Smooth Experience**: No physics glitches or unexpected behavior
✅ **Consistent**: All enemies behave predictably
✅ **Performance**: Lighter than physics-based enemies

## When to Use Each Component

### RayCast2D - FloorDetector
**Use when**: Enemy needs to stay on ground or follow terrain
- Ground-walking enemies (Slug)
- Enemies that need to be positioned on floor at spawn (Spit)

### RayCast2D - WallDetector
**Use when**: Enemy needs to detect walls to change direction
- Patrolling enemies (Slug)
- Enemies that bounce off walls (Bird uses boundary checking instead)

### Area2D - HitBox
**Use when**: Enemy can damage player (almost always)
- Set `collision_layer = 8` (enemy layer)
- Set `collision_mask = 1` (player layer)

## Common Patterns

### Boundary Checking (for flying enemies)

```gdscript
func check_boundaries():
    var room_width = 360
    var margin = 5

    if global_position.x <= margin:
        direction = 1
    elif global_position.x >= room_width - margin:
        direction = -1
```

### Dynamic RayCast Direction

```gdscript
func update_wall_detector_direction():
    """Update raycast to point in movement direction"""
    if wall_detector:
        wall_detector.target_position = Vector2(15 * direction, 0)
```

### Sprite Flipping

```gdscript
func update_sprite_flip():
    if animated_sprite:
        animated_sprite.flip_h = (direction > 0)  # or < 0, depends on sprite
```

## Migration from CharacterBody2D

If you have existing enemies using `CharacterBody2D`:

1. Change root node from `CharacterBody2D` to `Node2D`
2. Remove physical `CollisionShape2D`
3. Keep `HitBox` (Area2D) for damage detection
4. Add RayCasts as needed for floor/wall detection
5. Replace `velocity` + `move_and_slide()` with manual position updates
6. Replace `is_on_floor()` with `floor_detector.is_colliding()`
7. Replace `is_on_wall()` with `wall_detector.is_colliding()`

## Testing Checklist

When implementing a new enemy:

- [ ] Player can walk through enemy without getting stuck
- [ ] Enemy still damages player on contact
- [ ] Enemy is positioned correctly on floor (if ground enemy)
- [ ] Enemy changes direction at walls (if applicable)
- [ ] Enemy can be destroyed in metal mode
- [ ] Player doesn't get crushed between enemy and wall
- [ ] Enemy doesn't get "glued" to player when player is launched

## Conclusion

This pattern eliminates an entire class of bugs by separating **visual representation** from **damage detection** and removing **physical collision** entirely. While it requires manual movement implementation, the benefits in stability and maintainability far outweigh the small amount of extra code.

---

**Result**: Zero collision bugs, smooth gameplay, happy players! 🎮✨
