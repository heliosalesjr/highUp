extends Node2D

const ROOM_HEIGHT = 320
const SCREEN_HEIGHT = 1280
const INITIAL_ROOMS = 5  # Começa com menos salas
const ROOMS_AHEAD = 3    # Quantas salas manter acima do player

var room_scene = preload("res://scenes/room.tscn")
var rooms = []
var room_manager
var highest_room_created = -1  # Índice da sala mais alta criada

func _ready():
	print("=== MAIN READY ===")
	
	# Pega o RoomManager
	room_manager = get_node_or_null("/root/RoomManager")
	if not room_manager:
		print("AVISO: RoomManager não encontrado como Autoload")
	
	# Cria salas iniciais
	create_rooms()

func create_rooms():
	"""Cria as salas iniciais"""
	for i in range(INITIAL_ROOMS):
		create_room(i)

func create_room(index: int):
	"""Cria uma sala específica"""
	var room = room_scene.instantiate()
	
	# Alterna escada: par = direita, ímpar = esquerda
	if index % 2 == 0:
		room.ladder_side = 1  # RIGHT
	else:
		room.ladder_side = 0  # LEFT
	
	# Calcula posição Y
	# Sala 0 em Y=960, sala 1 em Y=640, sala 2 em Y=320, sala 3 em Y=0, sala 4 em Y=-320...
	var y_pos = (SCREEN_HEIGHT - ROOM_HEIGHT) - (index * ROOM_HEIGHT)
	room.position = Vector2(0, y_pos)
	room.name = "Room_" + str(index)
	
	add_child(room)
	rooms.append(room)
	
	# Popula a sala com conteúdo procedural
	if room_manager:
		# Aguarda um frame para garantir que a sala está pronta
		await get_tree().process_frame
		room_manager.populate_room(room, index)
	
	highest_room_created = max(highest_room_created, index)
	print("Room ", index, " criada em Y = ", y_pos)

func generate_rooms_ahead(current_room_index: int):
	"""Gera salas à frente do player conforme necessário"""
	
	# Calcula até qual sala devemos ter criado
	var target_room = current_room_index + ROOMS_AHEAD
	
	# Cria salas que ainda não existem
	if target_room > highest_room_created:
		for i in range(highest_room_created + 1, target_room + 1):
			create_room(i)
			print("→ Gerando sala ", i, " proceduralmente")

func _process(_delta):
	# Debug: mostra quantas salas existem
	if Input.is_action_just_pressed("ui_select"):  # Tecla Space
		print("Total de salas: ", rooms.size(), " | Sala mais alta: ", highest_room_created)
