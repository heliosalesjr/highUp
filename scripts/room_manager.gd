extends Node

# Singleton/Autoload que gerencia a geração de conteúdo nas salas

const ROOM_WIDTH = 720
const ROOM_HEIGHT = 320

# Arrays de cenas disponíveis (você vai popular isso)
var available_obstacles: Array[PackedScene] = []
var available_enemies: Array[PackedScene] = []
var available_traps: Array[PackedScene] = []

func _ready():
	# Registra os obstáculos/inimigos disponíveis
	load_available_elements()

func load_available_elements():
	"""Carrega todas as cenas de obstáculos/inimigos disponíveis"""
	
	# Carrega o spike (verifique se o caminho está correto!)
	var spike_scene = load("res://scenes/spike_static.tscn")
	if spike_scene:
		register_obstacle(spike_scene)
		print("✓ Spike carregado com sucesso!")
	else:
		print("✗ ERRO: Não conseguiu carregar spike_static.tscn")
	
	print("RoomManager: ", available_obstacles.size(), " obstáculos, ", 
		  available_enemies.size(), " inimigos, ", 
		  available_traps.size(), " armadilhas carregadas")

# Configurações de spawn por zona
var spawn_config = {
	"easy": {  # Salas 1-5
		"min_elements": 0,
		"max_elements": 1,
		"enemy_chance": 0.2,
		"obstacle_chance": 0.4,
		"trap_chance": 0.1
	},
	"medium": {  # Salas 6-15
		"min_elements": 1,
		"max_elements": 2,
		"enemy_chance": 0.4,
		"obstacle_chance": 0.5,
		"trap_chance": 0.3
	},
	"hard": {  # Salas 16+
		"min_elements": 1,
		"max_elements": 3,
		"enemy_chance": 0.6,
		"obstacle_chance": 0.6,
		"trap_chance": 0.5
	}
}

func populate_room(room: Node2D, room_index: int):
	"""
	Popula uma sala com obstáculos/inimigos/armadilhas
	room: o nó da sala
	room_index: índice da sala (0, 1, 2, ...)
	"""
	
	# Sala 0 sempre fica vazia (sala inicial)
	if room_index == 0:
		return
	
	# Determina a zona de dificuldade
	var zone = get_difficulty_zone(room_index)
	var config = spawn_config[zone]
	
	# Decide quantos elementos spawnar
	var num_elements = randi_range(config.min_elements, config.max_elements)
	
	print("Populando Room ", room_index, " (zona: ", zone, ") com ", num_elements, " elementos")
	
	# Spawna os elementos
	for i in range(num_elements):
		spawn_random_element(room, room_index, config)

func get_difficulty_zone(room_index: int) -> String:
	"""Retorna a zona de dificuldade baseada no índice da sala"""
	if room_index <= 5:
		return "easy"
	elif room_index <= 15:
		return "medium"
	else:
		return "hard"

func spawn_random_element(room: Node2D, room_index: int, config: Dictionary):
	"""Spawna um elemento aleatório baseado nas probabilidades"""
	
	var rand_value = randf()
	var element_scene: PackedScene = null
	var element_type = ""
	
	# Decide qual tipo de elemento spawnar baseado nas chances
	if rand_value < config.obstacle_chance:
		element_type = "obstacle"
		element_scene = get_random_obstacle()
	elif rand_value < config.obstacle_chance + config.enemy_chance:
		element_type = "enemy"
		element_scene = get_random_enemy()
	elif rand_value < config.obstacle_chance + config.enemy_chance + config.trap_chance:
		element_type = "trap"
		element_scene = get_random_trap()
	
	# Se conseguiu escolher algo, instancia
	if element_scene:
		var element = element_scene.instantiate()
		
		# Define posição aleatória
		var spawn_pos = get_random_spawn_position()
		element.position = spawn_pos
		
		room.add_child(element)
		print("  - Spawnou ", element_type, " em ", spawn_pos)

func get_random_spawn_position() -> Vector2:
	"""Retorna uma posição aleatória válida dentro da sala"""
	
	# Posições pré-definidas (evita spawnar nas paredes ou muito perto da escada)
	var positions = [
		Vector2(100, 250),   # Esquerda-baixo
		Vector2(250, 250),   # Centro-baixo
		Vector2(500, 250),   # Direita-baixo
		Vector2(100, 150),   # Esquerda-meio
		Vector2(360, 150),   # Centro-meio
		Vector2(500, 150),   # Direita-meio
	]
	
	return positions[randi() % positions.size()]

func get_random_obstacle() -> PackedScene:
	"""Retorna um obstáculo aleatório"""
	if available_obstacles.is_empty():
		return null
	return available_obstacles[randi() % available_obstacles.size()]

func get_random_enemy() -> PackedScene:
	"""Retorna um inimigo aleatório"""
	if available_enemies.is_empty():
		return null
	return available_enemies[randi() % available_enemies.size()]

func get_random_trap() -> PackedScene:
	"""Retorna uma armadilha aleatória"""
	if available_traps.is_empty():
		return null
	return available_traps[randi() % available_traps.size()]

func register_obstacle(scene: PackedScene):
	"""Adiciona um obstáculo ao pool de spawn"""
	available_obstacles.append(scene)

func register_enemy(scene: PackedScene):
	"""Adiciona um inimigo ao pool de spawn"""
	available_enemies.append(scene)

func register_trap(scene: PackedScene):
	"""Adiciona uma armadilha ao pool de spawn"""
	available_traps.append(scene)
