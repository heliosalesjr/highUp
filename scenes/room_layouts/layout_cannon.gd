# layout_cannon.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160

var cannon_scene = preload("res://scenes/obstacles/cannon.tscn")
var diamond_scene = preload("res://scenes/prize/diamond.tscn")
var heart_scene = preload("res://scenes/prize/heart.tscn")

func _ready():
	# create_label("CANNON ROOM")  # Hidden for now
	spawn_cannon()
	spawn_prize_randomly()
	create_room_entry_detector()

func create_label(text: String):
	var label = Label.new()
	label.text = text
	label.position = Vector2(ROOM_WIDTH / 2.0 - 70, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.CYAN)
	add_child(label)

func spawn_cannon():
	"""Spawna o canhão no centro da sala"""
	var cannon = cannon_scene.instantiate()
	cannon.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 20)  # Centro, próximo ao chão
	add_child(cannon)
	print("🚀 Canhão spawnado em: ", cannon.position)

func spawn_prize_randomly():
	"""50% de chance de spawnar um prêmio no topo"""
	if randf() > 0.5:
		return
	
	# Prêmio no topo para coletar durante o voo
	var prize_position = Vector2(ROOM_WIDTH / 2.0, 25)
	
	if GameManager.can_spawn_heart():
		var heart = heart_scene.instantiate()
		heart.position = prize_position
		add_child(heart)
		print("❤️ Coração spawnado no topo!")
	else:
		var diamond = diamond_scene.instantiate()
		diamond.position = prize_position
		add_child(diamond)
		print("💎 Diamante spawnado no topo!")

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
		print("🎯 Sala cannon alcançada!")
		get_node("EntryDetector").queue_free()
