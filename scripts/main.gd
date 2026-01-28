# main.gd
extends Node2D

const ROOM_HEIGHT = 160
const SCREEN_HEIGHT = 640
const INITIAL_ROOMS = 5
const ROOMS_AHEAD = 5
const ROOMS_BEHIND = 3  # ← NOVO: Quantas salas manter atrás do player
const CLEANUP_THRESHOLD = 10  # ← NOVO: Remove salas mais de 10 abaixo

var room_scene = preload("res://scenes/room.tscn")
var rooms = []
var room_manager
var highest_room_created = -1
var player = null  # ← NOVO: Referência ao player
var last_room_was_split = false  # Rastreia se a última sala foi split
var is_boss_fight = false
var boss_arena = null

func _ready():
	print("=== MAIN READY ===")
	
	GameManager.reset()
	
	room_manager = get_node_or_null("/root/RoomManager")
	if not room_manager:
		print("AVISO: RoomManager não encontrado como Autoload")
	
	create_rooms()

	# Encontra o player
	await get_tree().process_frame  # Aguarda tudo estar pronto
	find_player()

	GameManager.boss_fight_triggered.connect(start_boss_fight)

func find_player():
	"""Encontra o player na cena"""
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		# Tenta buscar pelo nome
		player = get_node_or_null("Player")
	
	if player:
		print("✅ Player encontrado!")
	else:
		print("⚠️ AVISO: Player não encontrado! Adicione o player ao grupo 'player'")

func _process(delta):
	# Gerencia salas baseado na posição do player
	if player:
		manage_rooms()
	
	# Debug
	if Input.is_action_just_pressed("ui_select"):
		print("Total de salas ativas: ", rooms.size(), " | Sala mais alta: ", highest_room_created)
		if player:
			print("Player na sala aproximada: ", get_current_room_index())

func manage_rooms():
	"""Gerencia criação e destruição de salas baseado na posição do player"""
	if is_boss_fight:
		return

	var current_room_index = get_current_room_index()
	
	# Gera salas à frente
	generate_rooms_ahead(current_room_index)
	
	# Remove salas antigas
	cleanup_old_rooms(current_room_index)

func get_current_room_index() -> int:
	"""Calcula em qual sala o player está aproximadamente"""
	if not player:
		return 0
	
	# Calcula baseado na posição Y do player
	var player_y = player.global_position.y
	var base_y = SCREEN_HEIGHT - ROOM_HEIGHT
	
	# Quanto mais negativo o Y, mais alto está
	var rooms_above = int((base_y - player_y) / ROOM_HEIGHT)
	
	return max(0, rooms_above)

func cleanup_old_rooms(current_room_index: int):
	"""Remove salas que estão muito abaixo do player"""
	var threshold = current_room_index - CLEANUP_THRESHOLD
	
	if threshold <= 0:
		return  # Ainda não há salas para remover
	
	# Percorre salas de trás pra frente para remover com segurança
	for i in range(rooms.size() - 1, -1, -1):
		var room = rooms[i]
		if not is_instance_valid(room):
			rooms.remove_at(i)
			continue
		
		# Extrai o índice do nome da sala (ex: "Room_5" → 5)
		var room_index = int(room.name.split("_")[1])
		
		if room_index < threshold:
			print("🗑️ Removendo sala antiga: ", room.name, " (player na sala ~", current_room_index, ")")
			room.queue_free()
			rooms.remove_at(i)

func create_rooms():
	"""Cria as salas iniciais"""
	for i in range(INITIAL_ROOMS):
		create_room(i)

func create_room(index: int):
	"""Cria uma sala específica"""

	print("→ Criando Room ", index)

	var room = room_scene.instantiate()

	var is_split = false
	if room_manager and index > 0:
		# Split a cada 5 salas OU 50% de chance se a anterior foi split
		if index % 5 == 0:
			is_split = true
			print("  ! Sala ", index, " marcada como SPLIT (a cada 5 salas)")
		elif last_room_was_split and randf() < 0.5:
			is_split = true
			print("  ! Sala ", index, " marcada como SPLIT (50% chance - sala anterior era split)")

	if is_split:
		room.is_split_room = true

	# Atualiza o rastreamento para a próxima sala
	last_room_was_split = is_split
	
	if not is_split:
		if index % 2 == 0:
			room.ladder_side = 1
		else:
			room.ladder_side = 0
	
	var y_pos = (SCREEN_HEIGHT - ROOM_HEIGHT) - (index * ROOM_HEIGHT)
	room.position = Vector2(0, y_pos)
	room.name = "Room_" + str(index)
	
	add_child(room)
	rooms.append(room)
	highest_room_created = max(highest_room_created, index)
	
	if room_manager and index > 0:
		room_manager.populate_room(room, index)
	
	print("  ✓ Room ", index, " completa em Y=", y_pos)

func generate_rooms_ahead(current_room_index: int):
	"""Gera salas à frente do player conforme necessário"""

	var target_room = current_room_index + ROOMS_AHEAD

	for i in range(highest_room_created + 1, target_room + 1):
		create_room(i)
		print("→ Gerando sala ", i, " proceduralmente (player na sala ~", current_room_index, ")")

func start_boss_fight():
	"""Inicia a boss fight"""
	print("🏟️ INICIANDO BOSS FIGHT!")
	is_boss_fight = true

	# Hide player
	if player:
		player.visible = false
		player.set_physics_process(false)

	# Lock camera at current position
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.is_locked = true

	# Create boss room centered on camera view
	# Arena is 360x320, camera center = viewport center
	# Arena top-left at (0, cam_y - 160) so it's vertically centered
	var arena_script = load("res://scripts/boss_arena.gd")
	boss_arena = Node2D.new()
	boss_arena.set_script(arena_script)

	var cam_y = 320.0
	if camera:
		cam_y = camera.global_position.y
	# Set position BEFORE add_child so _ready() has correct global_position
	boss_arena.position = Vector2(0, cam_y - 160)
	add_child(boss_arena)

	# Connect signals
	boss_arena.boss_defeated.connect(_on_boss_defeated)
	boss_arena.boss_failed.connect(_on_boss_failed)

func _on_boss_defeated():
	"""Boss derrotado - continua o jogo"""
	print("🎉 Boss derrotado! Continuando o jogo...")
	end_boss_fight()

func _on_boss_failed():
	"""Boss venceu - game over"""
	print("💀 Boss venceu! Game Over!")
	if boss_arena:
		boss_arena.queue_free()
		boss_arena = null
	is_boss_fight = false
	# Go directly to game over screen
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")

func end_boss_fight():
	"""Termina a boss fight e restaura o jogo normal"""
	var arena_pos_y = 0.0
	if boss_arena:
		arena_pos_y = boss_arena.global_position.y
		boss_arena.queue_free()
		boss_arena = null

	# Restore player at top of where arena was
	if player:
		player.visible = true
		player.set_physics_process(true)
		player.global_position = Vector2(180, arena_pos_y + 50)
		player.velocity = Vector2.ZERO

	# Unlock camera
	var camera = get_tree().get_first_node_in_group("camera")
	if camera:
		camera.is_locked = false

	is_boss_fight = false
	GameManager.boss_defeated = true

	# Generate rooms ahead so the game can continue
	var current_room_index = get_current_room_index()
	generate_rooms_ahead(current_room_index)
