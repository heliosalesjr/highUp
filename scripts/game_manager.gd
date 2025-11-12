# game_manager.gd
extends Node

signal rooms_changed(new_value)
signal diamonds_changed(new_value)
signal hearts_changed(filled_hearts)
signal player_died()

var rooms_count = 0
var diamonds_count = 0
var filled_hearts = 0
var diamonds_since_last_heart = 0  # ← NOVO: conta diamantes desde o último coração

const DIAMONDS_BEFORE_HEART = 2  # ← A cada 2 diamantes, spawna coração

func add_room():
	"""Adiciona um ponto de sala"""
	rooms_count += 1
	rooms_changed.emit(rooms_count)
	print("📊 Rooms: ", rooms_count)

func add_diamond():
	"""Adiciona um diamante coletado"""
	diamonds_count += 1
	diamonds_changed.emit(diamonds_count)
	
	# Incrementa contador
	diamonds_since_last_heart += 1
	
	print("💎 Diamonds: ", diamonds_count, " | Próximo coração em: ", DIAMONDS_BEFORE_HEART - diamonds_since_last_heart + 1, " diamantes")

func add_heart():
	"""Adiciona um coração diretamente"""
	if filled_hearts < 3:
		filled_hearts += 1
		diamonds_since_last_heart = 0  # Reseta o contador
		hearts_changed.emit(filled_hearts)
		print("❤️ Coração adicionado! Total: ", filled_hearts)
	else:
		print("❤️ Já tem 3 corações! (máximo)")

func should_spawn_heart() -> bool:
	"""
	Verifica se o próximo prêmio deve ser um coração.
	Retorna true se: já pegou 2 diamantes E não tem 3 corações cheios ainda
	"""
	return diamonds_since_last_heart >= DIAMONDS_BEFORE_HEART and filled_hearts < 3

func take_damage() -> bool:
	"""
	Player leva dano.
	Retorna true se sobreviveu, false se morreu.
	"""
	if filled_hearts > 0:
		filled_hearts -= 1
		hearts_changed.emit(filled_hearts)
		
		print("💔 Perdeu um coração! Restam: ", filled_hearts)
		return true
	else:
		print("💀 Player morreu!")
		player_died.emit()
		return false

func reset():
	"""Reseta os contadores"""
	rooms_count = 0
	diamonds_count = 0
	filled_hearts = 0
	diamonds_since_last_heart = 0
	rooms_changed.emit(rooms_count)
	diamonds_changed.emit(diamonds_count)
	hearts_changed.emit(filled_hearts)
