# layout_mist.gd
extends Node2D

const ROOM_WIDTH = 360
const ROOM_HEIGHT = 160

var chest_scene = preload("res://scenes/obstacles/chest.tscn")
var diamond_scene = preload("res://scenes/prize/diamond.tscn")
var heart_scene = preload("res://scenes/prize/heart.tscn")

func _ready():
	spawn_mist_chest()
	# NÃO spawna collectibles extras - apenas o chest aparece sozinho
	create_room_entry_detector()

func spawn_mist_chest():
	"""Spawna o chest com powerup de mist no chão da sala"""
	# Verifica se pode spawnar mist
	if not GameManager.can_spawn_mist():
		print("🌫️ Não spawnou chest de mist: modo já ativo")
		return

	var chest = chest_scene.instantiate()
	chest.powerup_type = "mist"
	# Posiciona no chão, centro horizontal
	chest.position = Vector2(ROOM_WIDTH / 2.0, ROOM_HEIGHT - 25)
	add_child(chest)
	print("📦 Chest de Mist spawnado!")

func spawn_extra_collectibles():
	"""Spawna diamantes/corações extras nos cantos"""
	var positions = [
		Vector2(50, 40),         # Canto superior esquerdo
		Vector2(ROOM_WIDTH - 50, 40),  # Canto superior direito
		Vector2(75, ROOM_HEIGHT - 40), # Canto inferior esquerdo
		Vector2(ROOM_WIDTH - 75, ROOM_HEIGHT - 40)  # Canto inferior direito
	]

	for pos in positions:
		if randf() > 0.3:  # 70% de chance de spawnar
			if GameManager.can_spawn_heart() and randf() > 0.7:
				var heart = heart_scene.instantiate()
				heart.position = pos
				add_child(heart)
			else:
				var diamond = diamond_scene.instantiate()
				diamond.position = pos
				add_child(diamond)

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
		print("🎯 Sala mist alcançada!")
		get_node("EntryDetector").queue_free()
