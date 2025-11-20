# game_over.gd
extends Control

@onready var rooms_label = $Panel/StatsContainer/RoomsLabel
@onready var diamonds_label = $Panel/StatsContainer/DiamondsLabel
@onready var ok_button = $Panel/OkButton

func _ready():
	# Conecta o botão
	ok_button.pressed.connect(_on_ok_pressed)
	
	# Atualiza as estatísticas
	update_stats()

func update_stats():
	"""Atualiza os números da partida"""
	rooms_label.text = "Rooms: " + str(GameManager.rooms_count)
	diamonds_label.text = "Diamonds: " + str(GameManager.diamonds_count)
	
	print("📊 Game Over - Rooms: ", GameManager.rooms_count, " | Diamonds: ", GameManager.diamonds_count)

func _on_ok_pressed():
	"""Volta para o menu principal"""
	print("👋 Voltando ao menu...")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
