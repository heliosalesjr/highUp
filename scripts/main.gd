# main.gd
extends Node2D

const ROOM_HEIGHT = 160
const SCREEN_HEIGHT = 640
const INITIAL_ROOMS = 5
const ROOMS_AHEAD = 5
const ROOMS_BEHIND = 3  # ← NOVO: Quantas salas manter atrás do player
const CLEANUP_THRESHOLD = 10  # ← NOVO: Remove salas mais de 10 abaixo

# Intro cutscene - floor da primeira room no meio da tela
const FIRST_ROOM_FLOOR_Y = 320  # Posição Y do floor da room 0
const FLOOR_LOCAL_Y = 154  # ROOM_HEIGHT - FLOOR_THICKNESS (160 - 6)
const FIRST_ROOM_Y = FIRST_ROOM_FLOOR_Y - FLOOR_LOCAL_Y  # ≈ 166

var room_scene = preload("res://scenes/room.tscn")
var rooms = []
var room_manager
var highest_room_created = -1
var player = null  # ← NOVO: Referência ao player
var last_room_was_split = false  # Rastreia se a última sala foi split

# Intro cutscene
var intro_active = true
const INTRO_PLAYER_START_Y = 700  # Player começa abaixo da tela
const INTRO_LAUNCH_VELOCITY = -1000.0  # Velocidade de lançamento para cima

func _ready():
	print("=== MAIN READY ===")

	GameManager.reset()

	room_manager = get_node_or_null("/root/RoomManager")
	if not room_manager:
		print("AVISO: RoomManager não encontrado como Autoload")

	# Cria paredes laterais para a área de lançamento (abaixo da room 0)
	create_intro_walls()

	create_rooms()

	# Encontra o player
	await get_tree().process_frame  # Aguarda tudo estar pronto
	find_player()

	# Inicia a cutscene de entrada
	if player and intro_active:
		start_intro_cutscene()


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

	# Base Y é o floor da room 0 (que agora está no meio da tela)
	var base_y = FIRST_ROOM_FLOOR_Y

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

	# Boss 3 room takes 2 slots - skip the second slot
	if index == GameManager.BOSS_3_ROOM_NUMBER + 1 and highest_room_created >= GameManager.BOSS_3_ROOM_NUMBER:
		highest_room_created = max(highest_room_created, index)
		return

	# Create boss 3 room (highest priority for testing)
	if index == GameManager.BOSS_3_ROOM_NUMBER and not GameManager.boss_3_defeated:
		create_boss3_room(index)
		return

	# Boss 2 room takes 2 slots - skip the second slot
	if index == GameManager.BOSS_2_ROOM_NUMBER + 1 and highest_room_created >= GameManager.BOSS_2_ROOM_NUMBER:
		highest_room_created = max(highest_room_created, index)
		return

	# Create boss 2 room instead of normal room
	if index == GameManager.BOSS_2_ROOM_NUMBER and not GameManager.boss_2_defeated:
		create_boss2_room(index)
		return

	# Boss room takes 2 slots - skip the second slot
	if index == GameManager.BOSS_ROOM_NUMBER + 1 and highest_room_created >= GameManager.BOSS_ROOM_NUMBER:
		highest_room_created = max(highest_room_created, index)
		return

	# Create boss room instead of normal room
	if index == GameManager.BOSS_ROOM_NUMBER and not GameManager.boss_defeated:
		create_boss_room(index)
		return

	print("→ Criando Room ", index)

	var room = room_scene.instantiate()

	var is_split = false
	if room_manager and index > 0:
		# Split a cada 5 salas OU 50% de chance se a anterior foi split
		if index % 5 == 0:
			is_split = true
			print("  ! Sala ", index, " marcada como SPLIT (a cada 5 salas)")
		elif last_room_was_split and randf() < 0.4:
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

	# Room 0 tem floor no meio da tela, as outras ficam acima
	var y_pos = FIRST_ROOM_Y - (index * ROOM_HEIGHT)
	room.position = Vector2(0, y_pos)
	room.name = "Room_" + str(index)

	add_child(room)
	rooms.append(room)
	highest_room_created = max(highest_room_created, index)

	if room_manager and index > 0:
		room_manager.populate_room(room, index)

	print("  ✓ Room ", index, " completa em Y=", y_pos)

func create_boss_room(index: int):
	"""Cria a sala do boss fight (2x altura)"""
	print("→ Criando BOSS Room ", index)

	var boss_room_script = load("res://scenes/boss/boss_room.gd")
	var room = Node2D.new()
	room.set_script(boss_room_script)

	# Position: 160px higher than normal room to cover 2 slots
	# Boss room floor aligns with where normal room floor would be
	var y_pos = FIRST_ROOM_Y - (index * ROOM_HEIGHT) - ROOM_HEIGHT
	room.position = Vector2(0, y_pos)
	room.name = "Room_" + str(index)

	add_child(room)
	rooms.append(room)
	# Mark both slots as created (boss room covers 2 room heights)
	highest_room_created = max(highest_room_created, index + 1)

	print("  ✓ BOSS Room ", index, " criada em Y=", y_pos)

func create_boss3_room(index: int):
	"""Cria a sala do boss 3 fight (2x altura)"""
	print("→ Criando BOSS 3 Room ", index)

	var boss3_room_script = load("res://scenes/boss/boss3_room.gd")
	var room = Node2D.new()
	room.set_script(boss3_room_script)

	# Position: 160px higher than normal room to cover 2 slots
	var y_pos = FIRST_ROOM_Y - (index * ROOM_HEIGHT) - ROOM_HEIGHT
	room.position = Vector2(0, y_pos)
	room.name = "Room_" + str(index)

	add_child(room)
	rooms.append(room)
	# Mark both slots as created (boss room covers 2 room heights)
	highest_room_created = max(highest_room_created, index + 1)

	print("  ✓ BOSS 3 Room ", index, " criada em Y=", y_pos)

func create_boss2_room(index: int):
	"""Cria a sala do boss 2 fight (2x altura)"""
	print("→ Criando BOSS 2 Room ", index)

	var boss2_room_script = load("res://scenes/boss/boss2_room.gd")
	var room = Node2D.new()
	room.set_script(boss2_room_script)

	# Position: 160px higher than normal room to cover 2 slots
	var y_pos = FIRST_ROOM_Y - (index * ROOM_HEIGHT) - ROOM_HEIGHT
	room.position = Vector2(0, y_pos)
	room.name = "Room_" + str(index)

	add_child(room)
	rooms.append(room)
	# Mark both slots as created (boss room covers 2 room heights)
	highest_room_created = max(highest_room_created, index + 1)

	print("  ✓ BOSS 2 Room ", index, " criada em Y=", y_pos)

func generate_rooms_ahead(current_room_index: int):
	"""Gera salas à frente do player conforme necessário"""

	var target_room = current_room_index + ROOMS_AHEAD

	for i in range(highest_room_created + 1, target_room + 1):
		create_room(i)
		print("→ Gerando sala ", i, " proceduralmente (player na sala ~", current_room_index, ")")

func create_intro_walls():
	"""Cria paredes laterais para a área de lançamento (abaixo da room 0)"""
	const WALL_THICKNESS = 6
	const ROOM_WIDTH = 360

	# Altura das paredes: desde a room 0 até bem abaixo da tela
	var wall_height = 600  # Cobre desde room 0 até abaixo do ponto de spawn
	var wall_top_y = FIRST_ROOM_Y + ROOM_HEIGHT  # Começa no fundo da room 0

	# Parede esquerda
	var left_wall = StaticBody2D.new()
	left_wall.name = "IntroLeftWall"

	var left_collision = CollisionShape2D.new()
	var left_shape = RectangleShape2D.new()
	left_shape.size = Vector2(WALL_THICKNESS, wall_height)
	left_collision.shape = left_shape
	left_collision.position = Vector2(WALL_THICKNESS / 2.0, wall_height / 2.0)

	var left_visual = ColorRect.new()
	left_visual.size = Vector2(WALL_THICKNESS, wall_height)
	left_visual.color = Color(0.3, 0.3, 0.3)  # Cinza escuro

	left_wall.add_child(left_collision)
	left_wall.add_child(left_visual)
	left_wall.position = Vector2(0, wall_top_y)
	add_child(left_wall)

	# Parede direita
	var right_wall = StaticBody2D.new()
	right_wall.name = "IntroRightWall"

	var right_collision = CollisionShape2D.new()
	var right_shape = RectangleShape2D.new()
	right_shape.size = Vector2(WALL_THICKNESS, wall_height)
	right_collision.shape = right_shape
	right_collision.position = Vector2(WALL_THICKNESS / 2.0, wall_height / 2.0)

	var right_visual = ColorRect.new()
	right_visual.size = Vector2(WALL_THICKNESS, wall_height)
	right_visual.color = Color(0.3, 0.3, 0.3)  # Cinza escuro

	right_wall.add_child(right_collision)
	right_wall.add_child(right_visual)
	right_wall.position = Vector2(ROOM_WIDTH - WALL_THICKNESS, wall_top_y)
	add_child(right_wall)

	print("🧱 Paredes de intro criadas!")

func start_intro_cutscene():
	"""Inicia a cutscene de entrada - player é lançado de baixo para cima"""
	print("🎬 Iniciando cutscene de entrada!")

	# Posiciona player abaixo da tela
	player.global_position.y = INTRO_PLAYER_START_Y
	player.global_position.x = 180  # Centro horizontal

	# Pequeno delay antes de lançar
	await get_tree().create_timer(0.3).timeout

	# Lança o player para cima
	if player.has_method("intro_launch"):
		player.intro_launch(INTRO_LAUNCH_VELOCITY)
	else:
		# Fallback: usa launch_from_cannon se intro_launch não existir
		player.launch_from_cannon(INTRO_LAUNCH_VELOCITY)

	intro_active = false
	print("🎬 Player lançado!")
