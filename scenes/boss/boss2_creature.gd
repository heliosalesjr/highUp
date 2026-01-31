# boss2_creature.gd
extends CharacterBody2D

signal creature_hit
signal color_changed(new_color)

const MOVE_SPEED = 60.0
const CREATURE_WIDTH = 50
const CREATURE_HEIGHT = 36

var hp = 3
var is_attacking = false
var direction = 1
var current_color = "white"

func _ready():
	add_to_group("boss2_creature")
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

	# Visual: starts white
	var visual = ColorRect.new()
	visual.size = Vector2(CREATURE_WIDTH, CREATURE_HEIGHT)
	visual.position = Vector2(-CREATURE_WIDTH / 2.0, -CREATURE_HEIGHT / 2.0)
	visual.color = Color(1.0, 1.0, 1.0)
	visual.name = "Visual"
	add_child(visual)

	# Collision shape (for wall bouncing)
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(CREATURE_WIDTH, CREATURE_HEIGHT)
	collision.shape = shape
	add_child(collision)

func start_attacking():
	is_attacking = true
	collision_layer = 1
	collision_mask = 1
	set_physics_process(true)

func _physics_process(delta):
	if not is_attacking:
		return

	velocity.x = direction * MOVE_SPEED
	velocity.y = 0
	move_and_slide()

	if is_on_wall():
		direction *= -1

func start_round():
	# Pick random color for this round
	if randi() % 2 == 0:
		current_color = "cyan"
	else:
		current_color = "magenta"
	update_visual_color()
	color_changed.emit(current_color)

func set_color_white():
	current_color = "white"
	update_visual_color()

func update_visual_color():
	var visual = get_node_or_null("Visual")
	if visual:
		match current_color:
			"cyan":
				visual.color = Color(0.0, 1.0, 1.0)
			"magenta":
				visual.color = Color(1.0, 0.0, 1.0)
			_:
				visual.color = Color(1.0, 1.0, 1.0)

func get_current_color() -> String:
	return current_color

func take_hit():
	hp -= 1
	creature_hit.emit()
	flash_white()
	print("Boss 2 atingido! HP: ", hp)

	if hp <= 0:
		die()

func flash_white():
	var visual = get_node_or_null("Visual")
	if visual:
		visual.color = Color(1.0, 1.0, 1.0)
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(self) and visual:
			update_visual_color()

func grow_closer(new_scale: float, new_y: float):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(new_scale, new_scale), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", new_y, 0.6).set_ease(Tween.EASE_OUT)

func die():
	is_attacking = false
	set_physics_process(false)
	print("Boss 2 morreu!")

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
