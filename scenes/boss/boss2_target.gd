# boss2_target.gd
extends Area2D

const TARGET_WIDTH = 36
const TARGET_HEIGHT = 12

var target_color: String = "white"
var consumed = false
var visual: ColorRect = null

func _ready():
	add_to_group("boss2_target")
	collision_layer = 64
	collision_mask = 0
	monitoring = false
	monitorable = true

	# Visual
	visual = ColorRect.new()
	visual.size = Vector2(TARGET_WIDTH, TARGET_HEIGHT)
	visual.position = Vector2(-TARGET_WIDTH / 2.0, -TARGET_HEIGHT / 2.0)
	visual.color = Color(1.0, 1.0, 1.0)
	visual.name = "Visual"
	add_child(visual)

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(TARGET_WIDTH, TARGET_HEIGHT)
	collision.shape = shape
	add_child(collision)

func set_target_color(color_name: String):
	target_color = color_name
	if visual:
		match color_name:
			"cyan":
				visual.color = Color(0.0, 1.0, 1.0)
			"magenta":
				visual.color = Color(1.0, 0.0, 1.0)
			_:
				visual.color = Color(1.0, 1.0, 1.0)

func fall():
	consumed = true
	collision_layer = 0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y + 150, 0.4).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
