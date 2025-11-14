# main.gd
extends Node2D

const ROOM_HEIGHT = 320
const SCREEN_HEIGHT = 1280
const INITIAL_ROOMS = 5
const ROOMS_AHEAD = 5
const ROOMS_BEHIND = 3  # ← NOVO: Quantas salas manter atrás do player
const CLEANUP_THRESHOLD = 10  # ← NOVO: Remove salas mais de 10 abaixo

var room_scene = preload("res://scenes/room.tscn")
var rooms = []
var room_manager
var highest_room_created = -1
var player = null  # ← NOVO: Referência ao player

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
	if room_manager and index > 0 and index % 5 == 0:
		is_split = true
		room.is_split_room = true
		print("  ! Sala ", index, " marcada como SPLIT (sem escada)")
	
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
