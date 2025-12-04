# layout_saw.gd
extends Node2D

const ROOM_WIDTH = 720
const ROOM_HEIGHT = 320

var sawblade_scene = preload("res://scenes/obstacles/sawblade.tscn")
var diamond_scene = preload("res://scenes/prize/diamond.tscn")
var heart_scene = preload("res://scenes/prize/heart.tscn")

func _ready():
	create_label("SAW ROOM")
	spawn_sawblade()
	spawn_prize_randomly()
	create_room_entry_detector()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 50, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.RED)  # Vermelho para indicar perigo!
	add_child(label)

func spawn_sawblade():
	"""Spawna a sawblade no canto superior direito"""
	var sawblade = sawblade_scene.instantiate()
	# Posição inicial: canto superior direito
	sawblade.position = Vector2(ROOM_WIDTH - 50, 50)
	add_child(sawblade)
	print("🪚 Sawblade spawnada em: ", sawblade.position)

func spawn_prize_randomly():
	"""50% de chance de spawnar um prêmio no centro"""
	if randf() > 0.5:
		return
	
	var prize_position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT / 2.0)
	
	if GameManager.can_spawn_heart():
		var heart = heart_scene.instantiate()
		heart.position = prize_position
		add_child(heart)
		print("❤️ Coração spawnado no centro!")
	else:
		var diamond = diamond_scene.instantiate()
		diamond.position = prize_position
		add_child(diamond)
		print("💎 Diamante spawnado no centro!")

func create_room_entry_detector():
	"""Detecta quando o player entra na sala"""
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
		print("🎯 Sala saw alcançada!")
		get_node("EntryDetector").queue_free()
