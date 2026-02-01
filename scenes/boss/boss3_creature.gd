# boss3_creature.gd
extends Node2D

signal creature_hit

const BODY_WIDTH = 80
const BODY_HEIGHT = 60

var hp = 3

func _ready():
	z_index = -1

	# Body: dark red rectangle
	var body = ColorRect.new()
	body.size = Vector2(BODY_WIDTH, BODY_HEIGHT)
	body.position = Vector2(-BODY_WIDTH / 2.0, -BODY_HEIGHT / 2.0)
	body.color = Color(0.6, 0.08, 0.05)
	body.name = "Visual"
	add_child(body)

	# Left eye
	var left_eye = ColorRect.new()
	left_eye.size = Vector2(12, 12)
	left_eye.position = Vector2(-22, -18)
	left_eye.color = Color(1.0, 0.9, 0.1)
	left_eye.name = "LeftEye"
	add_child(left_eye)

	# Left pupil
	var left_pupil = ColorRect.new()
	left_pupil.size = Vector2(6, 6)
	left_pupil.position = Vector2(-19, -15)
	left_pupil.color = Color(0.0, 0.0, 0.0)
	add_child(left_pupil)

	# Right eye
	var right_eye = ColorRect.new()
	right_eye.size = Vector2(12, 12)
	right_eye.position = Vector2(10, -18)
	right_eye.color = Color(1.0, 0.9, 0.1)
	right_eye.name = "RightEye"
	add_child(right_eye)

	# Right pupil
	var right_pupil = ColorRect.new()
	right_pupil.size = Vector2(6, 6)
	right_pupil.position = Vector2(13, -15)
	right_pupil.color = Color(0.0, 0.0, 0.0)
	add_child(right_pupil)

	# Mouth: wide red line
	var mouth = ColorRect.new()
	mouth.size = Vector2(30, 6)
	mouth.position = Vector2(-15, 8)
	mouth.color = Color(0.9, 0.15, 0.1)
	mouth.name = "Mouth"
	add_child(mouth)

	# Start idle pulse animation
	start_pulse()

func start_pulse():
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func take_hit():
	hp -= 1
	creature_hit.emit()
	flash_white()
	# Shrink on hit
	var base = max(0.5, 1.0 - (3 - hp) * 0.15)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(base, base), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	print("Boss 3 atingido! HP: ", hp)

func flash_white():
	var visual = get_node_or_null("Visual")
	if visual:
		var original_color = visual.color
		visual.color = Color(1.0, 1.0, 1.0)
		modulate = Color(2.0, 2.0, 2.0)
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(self) and visual:
			visual.color = original_color
			modulate = Color(1.0, 1.0, 1.0)

func die():
	print("Boss 3 morreu!")
	# Stop pulse
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
