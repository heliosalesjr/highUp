# game_manager.gd
extends Node

signal rooms_changed(new_value)
signal diamonds_changed(new_value)
signal hearts_changed(filled_hearts)
signal player_died()

var rooms_count = 0
var diamonds_count = 0
var filled_hearts = 0
var diamonds_for_next_heart = 0  # ← NOVO: conta diamantes para o próximo coração

const DIAMONDS_PER_HEART = 3

func add_room():
	"""Adiciona um ponto de sala"""
	rooms_count += 1
	rooms_changed.emit(rooms_count)
	print("📊 Rooms: ", rooms_count)

func add_diamond():
	"""Adiciona um diamante coletado"""
	diamonds_count += 1
	diamonds_changed.emit(diamonds_count)
	
	# Incrementa o contador para o próximo coração
	diamonds_for_next_heart += 1
	
	# Verifica se completou um coração
	check_hearts()
	
	print("💎 Diamonds: ", diamonds_count, " | Para próximo coração: ", diamonds_for_next_heart, "/", DIAMONDS_PER_HEART)

func check_hearts():
	"""Verifica se deve ganhar um novo coração"""
	if diamonds_for_next_heart >= DIAMONDS_PER_HEART and filled_hearts < 3:
		# Ganha um coração!
		filled_hearts += 1
		diamonds_for_next_heart = 0  # Reseta o contador
		hearts_changed.emit(filled_hearts)
		print("❤️ Ganhou um coração! Total: ", filled_hearts)

func take_damage() -> bool:
	"""
	Player leva dano.
	Retorna true se sobreviveu, false se morreu.
	"""
	if filled_hearts > 0:
		# Perde um coração
		filled_hearts -= 1
		hearts_changed.emit(filled_hearts)
		
		print("💔 Perdeu um coração! Restam: ", filled_hearts)
		return true  # Sobreviveu
	else:
		# Sem corações = morte
		print("💀 Player morreu!")
		player_died.emit()
		return false  # Morreu

func reset():
	"""Reseta os contadores"""
	rooms_count = 0
	diamonds_count = 0
	filled_hearts = 0
	diamonds_for_next_heart = 0  # ← Reseta também
	rooms_changed.emit(rooms_count)
	diamonds_changed.emit(diamonds_count)
	hearts_changed.emit(filled_hearts)
