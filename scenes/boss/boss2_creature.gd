# boss2_creature.gd
extends CharacterBody2D

signal creature_hit

const MOVE_SPEED = 60.0
const SHOOT_INTERVAL = 1.5
const CREATURE_WIDTH = 40
const CREATURE_HEIGHT = 32

var hp = 5
var is_attacking = false
var shoot_timer = 0.0
var direction = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var room: Node2D = null

func _ready():
	add_to_group("boss2_creature")
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

	# Visual: purple rectangle
	var visual = ColorRect.new()
	visual.size = Vector2(CREATURE_WIDTH, CREATURE_HEIGHT)
	visual.position = Vector2(-CREATURE_WIDTH / 2.0, -CREATURE_HEIGHT / 2.0)
	visual.color = Color(0.6, 0.2, 0.8)
	visual.name = "Visual"
	add_child(visual)

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(CREATURE_WIDTH, CREATURE_HEIGHT)
	collision.shape = shape
	add_child(collision)

	# HitBox: Area2D that detects reflected projectiles
	var hitbox = Area2D.new()
	hitbox.name = "HitBox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 64  # Detect boss 2 projectiles (bit 7)
	hitbox.monitoring = true

	var hitbox_collision = CollisionShape2D.new()
	var hitbox_shape = RectangleShape2D.new()
	hitbox_shape.size = Vector2(CREATURE_WIDTH, CREATURE_HEIGHT)
	hitbox_collision.shape = hitbox_shape
	hitbox.add_child(hitbox_collision)

	hitbox.area_entered.connect(_on_hitbox_area_entered)
	add_child(hitbox)

func start_attacking():
	is_attacking = true
	collision_layer = 1  # Collide with walls to bounce
	collision_mask = 1
	shoot_timer = 0.0
	set_physics_process(true)
	print("👾 Criatura comecou a atacar!")

func _physics_process(delta):
	if not is_attacking:
		return

	# Horizontal movement only (creature floats at the top)
	velocity.x = direction * MOVE_SPEED
	velocity.y = 0
	move_and_slide()

	if is_on_wall():
		direction *= -1

	# Shoot timer
	shoot_timer += delta
	if shoot_timer >= SHOOT_INTERVAL:
		shoot_timer = 0.0
		shoot_projectile()

func shoot_projectile():
	var projectile_script = load("res://scenes/boss/boss2_projectile.gd")
	var projectile = Area2D.new()
	projectile.set_script(projectile_script)

	if room:
		room.add_child(projectile)
	else:
		get_parent().add_child(projectile)

	# Spawn below the creature
	projectile.global_position = global_position + Vector2(0, CREATURE_HEIGHT / 2.0 + 5)

func _on_hitbox_area_entered(area):
	if area.is_in_group("boss2_projectile") and area.is_reflected:
		take_hit()
		area.queue_free()

func take_hit():
	hp -= 1
	creature_hit.emit()
	flash_white()
	print("👾 Criatura atingida! HP: ", hp)

	if hp <= 0:
		die()

func flash_white():
	var visual = get_node_or_null("Visual")
	if visual:
		var original_color = visual.color
		visual.color = Color(1.0, 1.0, 1.0)
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(self) and visual:
			visual.color = original_color

func die():
	is_attacking = false
	set_physics_process(false)
	print("👾 Criatura morreu!")

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
