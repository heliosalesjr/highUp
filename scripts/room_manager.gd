extends Node

# Factory de obstáculos - cria instâncias baseadas em classes

enum ObstacleType { SPIKE, MOVING_SPIKE, SAW_BLADE }

# Padrões de spawn de spikes
# Room tem 720px de largura, centro em X=360
# Spike tem 40px de largura, seu position é o centro do spike
const ROOM_WIDTH = 720.0
const ROOM_CENTER_X = ROOM_WIDTH / 2.0  # 360
const SPIKE_WIDTH = 40.0
const SPIKE_Y = 300.0  # Altura padrão (perto do chão)

var spike_patterns = [
	# 1. Spike bem no meio da room
	[Vector2(ROOM_CENTER_X, SPIKE_Y)],
	
	# 2. Spike com CENTRO 20px à esquerda do centro da room
	[Vector2(ROOM_CENTER_X - 150, SPIKE_Y)],
	
	# 3. Spike com CENTRO 20px à direita do centro da room
	[Vector2(ROOM_CENTER_X + 150, SPIKE_Y)],
		
	# 4. Dois spikes encostados, começando 30px à esquerda do centro
	# O conjunto começa em X=330 (360-30)
	# Primeiro spike: centro em 330 + 20 = 350
	# Segundo spike (encostado): centro em 350 + 40 = 390
	# Ops, isso vai pra direita! Vamos recalcular:
	# Se queremos o conjunto à esquerda, os centros devem ser:
	# Spike 1: 330 - 20 = 310 (borda direita em 330)
	# Spike 2: 330 + 20 = 350 (borda esquerda em 330)
	[Vector2(ROOM_CENTER_X - 150, SPIKE_Y), Vector2(ROOM_CENTER_X - 100, SPIKE_Y)],
	
	# 5. Dois spikes encostados, começando 30px à direita do centro
	# O conjunto começa em X=390 (360+30)
	# Spike 1: 390 - 20 = 370 (borda direita em 390)
	# Spike 2: 390 + 20 = 410 (borda esquerda em 390)
	[Vector2(ROOM_CENTER_X + 100, SPIKE_Y), Vector2(ROOM_CENTER_X + 150, SPIKE_Y)],
	
	# 6. Dois spikes separados: um 40px à esquerda, outro 40px à direita do centro
	[Vector2(ROOM_CENTER_X - 180, SPIKE_Y), Vector2(ROOM_CENTER_X + 180, SPIKE_Y)]
]

# Configurações de spawn por zona
var spawn_config = {
	"easy": {
		"min_obstacles": 0,
		"max_obstacles": 1,
		"spike_chance": 0.5
	},
	"medium": {
		"min_obstacles": 1,
		"max_obstacles": 2,
		"spike_chance": 0.7
	},
	"hard": {
		"min_obstacles": 2,
		"max_obstacles": 3,
		"spike_chance": 0.8
	}
}

func populate_room(room: Node2D, room_index: int):
	"""Popula uma sala com obstáculos"""
	
	if room_index == 0:
		return
	
	# Determina zona
	var zone = get_difficulty_zone(room_index)
	var config = spawn_config[zone]
	
	# Chance de spawnar spikes
	if randf() > config.spike_chance:
		return
	
	# Descobre posição da escada
	var ladder = room.get_node_or_null("Ladder")
	var ladder_on_right = true
	if ladder:
		ladder_on_right = ladder.position.x > 360
	
	# Escolhe um padrão aleatório
	spawn_spike_pattern(room, room_index, ladder_on_right)

func spawn_spike_pattern(room: Node2D, room_index: int, ladder_on_right: bool):
	"""Spawna um padrão aleatório de spikes"""
	
	# Filtra padrões que não conflitam com a escada
	var valid_patterns = []
	
	for pattern in spike_patterns:
		var is_valid = true
		
		# Verifica se algum spike do padrão está muito perto da escada
		for spike_pos in pattern:
			if ladder_on_right and spike_pos.x > 420:
				is_valid = false
				break
			elif not ladder_on_right and spike_pos.x < 300:
				is_valid = false
				break
		
		if is_valid:
			valid_patterns.append(pattern)
	
	# Se não houver padrões válidos, não spawna nada
	if valid_patterns.is_empty():
		return
	
	# Escolhe um padrão aleatório válido
	var chosen_pattern = valid_patterns[randi() % valid_patterns.size()]
	
	# Spawna cada spike do padrão
	for spike_pos in chosen_pattern:
		var spike = Spike.new()
		spike.position = spike_pos
		room.add_child(spike)
	
	print("  ✓ Pattern com ", chosen_pattern.size(), " spike(s) em Room ", room_index)

func create_obstacle(type: ObstacleType) -> ObstacleBase:
	"""Factory method - cria obstáculos baseado no tipo"""
	
	match type:
		ObstacleType.SPIKE:
			return Spike.new()
		ObstacleType.MOVING_SPIKE:
			# Implementar depois
			return null
		ObstacleType.SAW_BLADE:
			# Implementar depois
			return null
	
	return null

func get_difficulty_zone(room_index: int) -> String:
	"""Retorna zona de dificuldade"""
	if room_index <= 5:
		return "easy"
	elif room_index <= 15:
		return "medium"
	else:
		return "hard"
