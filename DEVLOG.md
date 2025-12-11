# Development Log - High Up

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
