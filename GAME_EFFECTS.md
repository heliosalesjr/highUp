# Game Effects - High Up

Documentation for visual effects and game feel enhancements.

## Camera Shake System

### Overview

The camera shake system provides visual feedback when the player takes damage from enemies, creating a sense of impact and improving game feel. The shake is subtle but noticeable, enhancing the combat experience without being distracting.

### How It Works

The camera shake is triggered in **two different scenarios**:

1. **Normal Hit** - When player touches an enemy without Metal Mode active
2. **Metal Mode Hit** - When player touches an enemy while Metal Mode is active

Both scenarios use the **same shake parameters** for consistency.

### Architecture

```
Player touches Enemy
       │
       ├─── Has Metal Mode? ──YES──> be_freed() → trigger_camera_shake()
       │                              (Enemy freed)
       │
       └─── NO ──> take_damage() → trigger_hit_camera_shake()
                    (Player loses health)
```

### Implementation

#### 1. Camera Script (`scripts/camera_2d.gd`)

The camera has a built-in shake system:

```gdscript
var is_shaking = false
var shake_intensity = 0.0
var shake_time_remaining = 0.0

func shake(duration: float, intensity: float = 25.0):
    """Initiates camera shake"""
    is_shaking = true
    shake_time_remaining = duration
    shake_intensity = intensity

func process_shake(delta):
    """Processes shake every frame"""
    if is_shaking:
        shake_time_remaining -= delta

        if shake_time_remaining > 0:
            # Apply random offset
            offset = Vector2(
                randf_range(-shake_intensity, shake_intensity),
                randf_range(-shake_intensity, shake_intensity)
            )

            # Gradually reduce intensity
            shake_intensity = lerp(shake_intensity, 0.0, delta * 3.0)
        else:
            # End shake
            is_shaking = false
            offset = Vector2.ZERO
            shake_intensity = 0.0
```

**Key Features:**
- Random offset in both X and Y directions
- Intensity gradually decreases over time (lerp)
- Automatic cleanup when duration ends

#### 2. Player Hit (`scripts/player.gd`)

When player takes damage from an enemy:

```gdscript
func take_damage(enemy):
    """Called when player takes damage"""
    if is_invulnerable or launch_invulnerability or is_launched:
        return

    if enemy in damaged_enemies:
        return

    # Trigger camera shake
    trigger_hit_camera_shake()

    var survived = GameManager.take_damage()
    # ... rest of damage logic

func trigger_hit_camera_shake():
    """Activates camera shake on enemy hit"""
    var camera = get_tree().get_first_node_in_group("camera")
    if camera and camera.has_method("shake"):
        camera.shake(0.2, 10.0)  # Duration: 0.2s, intensity: 10 (subtle)
```

#### 3. Metal Mode Hit (Enemy Scripts)

When player in Metal Mode touches an enemy:

**Files:**
- `scenes/enemies/slug.gd`
- `scenes/enemies/bird.gd`
- `scenes/enemies/spit.gd`

```gdscript
func be_freed():
    """Animal is freed by metal mode"""
    if is_being_freed:
        return

    is_being_freed = true
    print("🦋 Enemy being FREED!")

    # Camera shake on hit
    trigger_camera_shake()

    GameManager.free_animal("EnemyName")
    # ... liberation effect logic

func trigger_camera_shake():
    """Activates camera shake when hitting enemy (metal mode)"""
    var camera = get_tree().get_first_node_in_group("camera")
    if camera and camera.has_method("shake"):
        camera.shake(0.2, 10.0)  # Duration: 0.2s, intensity: 10 (subtle)
```

### Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Duration** | 0.2 seconds | How long the shake lasts |
| **Intensity** | 10 pixels | Maximum offset in each direction |

**Why these values?**
- **0.2s**: Short enough to not be annoying, long enough to be noticed
- **10px**: Subtle movement that adds impact without disorienting the player
- The intensity **decreases gradually** (lerp), so it starts at 10px and smoothly reduces to 0

### Camera Group System

The shake system uses Godot's **group system** to find the camera:

```gdscript
# In camera_2d.gd _ready():
add_to_group("camera")

# In any script that needs the camera:
var camera = get_tree().get_first_node_in_group("camera")
```

**Advantages:**
- Decoupled: Enemies don't need direct reference to camera
- Flexible: Camera can be anywhere in the scene tree
- Scalable: Easy to add multiple cameras if needed

### When Shake is NOT Triggered

Camera shake is **not triggered** when:

1. **Player is invulnerable** (`is_invulnerable = true`)
   - During invulnerability period after taking damage

2. **Player is in launch state** (`is_launched = true`)
   - When launched by cannon

3. **Player has launch invulnerability** (`launch_invulnerability = true`)
   - Brief protection right after cannon launch

4. **Enemy already damaged player** (`enemy in damaged_enemies`)
   - Prevents multiple hits from same enemy during invulnerability

This prevents shake spam and maintains the effect's impact.

### Visual Feedback Chain

When player hits an enemy, multiple feedback systems activate simultaneously:

```
Player touches Enemy
       ↓
┌──────────────────────────────────────┐
│  CAMERA SHAKE (0.2s)                 │ ← Subtle screen movement
│  + Player invulnerability flash      │ ← Player blinks
│  + Enemy liberation effect           │ ← Enemy glows/escapes (Metal Mode)
│  + Heart/Shield loss UI update       │ ← HUD updates
└──────────────────────────────────────┘
```

All these effects work together to create a satisfying "game feel".

### Comparison with Other Shakes

The game has different shake intensities for different events:

| Event | Duration | Intensity | Purpose |
|-------|----------|-----------|---------|
| **Enemy Hit** | 0.2s | 10px | Subtle feedback on contact |
| **Cannon Launch** | 1.5s | 30px | Major event, high impact |

The enemy hit shake is intentionally **much more subtle** than the cannon launch to avoid overwhelming the player during regular gameplay.

## Modifying the Shake

### Making it More Intense

To increase intensity, modify these values:

```gdscript
# In player.gd and all enemy scripts
camera.shake(0.3, 20.0)  # Longer duration, higher intensity
```

### Making it More Subtle

To decrease intensity:

```gdscript
camera.shake(0.15, 5.0)  # Shorter duration, lower intensity
```

### Disabling Shake

To completely disable enemy hit shake:

**Option 1: Comment out the calls**
```gdscript
# In player.gd
func take_damage(enemy):
    # trigger_hit_camera_shake()  # ← Comment this line
```

**Option 2: Add a setting**
```gdscript
# In game settings
var enable_camera_shake = true

func trigger_hit_camera_shake():
    if not enable_camera_shake:
        return
    # ... rest of function
```

## Adding Shake to Other Events

To add camera shake to other events (e.g., collecting items, obstacles):

```gdscript
func on_special_event():
    var camera = get_tree().get_first_node_in_group("camera")
    if camera and camera.has_method("shake"):
        camera.shake(duration, intensity)
```

**Recommended values:**
- **Minor event** (pickup): `shake(0.1, 5.0)`
- **Medium event** (obstacle hit): `shake(0.2, 10.0)`
- **Major event** (boss hit): `shake(0.5, 30.0)`

## Files Reference

### Core System
- `scripts/camera_2d.gd` - Camera shake implementation
  - `shake()` - Initiates shake
  - `process_shake()` - Processes shake every frame

### Player
- `scripts/player.gd`
  - `take_damage()` - Calls shake on enemy hit
  - `trigger_hit_camera_shake()` - Triggers the shake effect

### Enemies (Metal Mode)
- `scenes/enemies/slug.gd`
- `scenes/enemies/bird.gd`
- `scenes/enemies/spit.gd`
  - `be_freed()` - Calls shake when freed
  - `trigger_camera_shake()` - Triggers the shake effect

## Testing

To test the camera shake:

1. **Normal Mode Test**:
   - Start game
   - Touch any enemy (Slug, Bird, Spit)
   - Should see subtle screen shake (0.2s)
   - Player will flash (invulnerability)
   - Health will decrease

2. **Metal Mode Test**:
   - Get Metal Potion powerup
   - Touch any enemy
   - Should see subtle screen shake (0.2s)
   - Enemy will glow and escape
   - No health lost

3. **Comparison Test**:
   - Get launched by cannon
   - Compare cannon shake (1.5s, intense) vs enemy hit shake (0.2s, subtle)
   - Enemy hit should be much more subtle

## Performance

The camera shake system is **very lightweight**:

- Only runs when `is_shaking = true`
- Uses simple `lerp()` and `randf_range()` functions
- No physics calculations
- Automatic cleanup

**Performance cost**: Negligible (~0.01ms per shake)

## Best Practices

### Do:
✅ Use consistent shake values for similar events
✅ Keep enemy hit shakes subtle (< 15px intensity)
✅ Use shorter durations for frequent events (< 0.3s)
✅ Test shake on different screen sizes

### Don't:
❌ Don't stack multiple shakes (they override each other)
❌ Don't use high intensity for frequent events (causes motion sickness)
❌ Don't shake for more than 2 seconds (annoying)
❌ Don't forget to test with shake disabled (accessibility)

## Accessibility Considerations

Some players may be sensitive to screen shake. Future improvements could include:

1. **Settings toggle** to disable shake
2. **Intensity slider** in options menu
3. **Per-event toggles** (keep major events, disable minor ones)

Example implementation:

```gdscript
# In GameManager or Settings
var camera_shake_intensity_multiplier = 1.0  # 0.0 = disabled, 1.0 = full

func trigger_shake(duration: float, intensity: float):
    var adjusted_intensity = intensity * camera_shake_intensity_multiplier
    camera.shake(duration, adjusted_intensity)
```

## Future Enhancements

Potential improvements to the shake system:

1. **Directional Shake**
   - Shake in direction of hit
   - More realistic impact feedback

2. **Different Shake Patterns**
   - Horizontal only for some events
   - Vertical only for others
   - Circular shake for explosions

3. **Shake Combos**
   - Increase intensity with consecutive hits
   - "Screen rumble" during intense moments

4. **Adaptive Shake**
   - Automatically adjust based on player preferences
   - Learn from player behavior (if they often disable it)
