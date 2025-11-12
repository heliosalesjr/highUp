# main_menu.gd
extends Control

@onready var play_button = $PlayButton
@onready var diamond_label = $DiamondStats/DiamondLabel
@onready var record_label = $RecordStats/RecordLabel

func _ready():
	# Conecta o botão
	play_button.pressed.connect(_on_play_pressed)
	
	# Atualiza as estatísticas
	update_stats()

func update_stats():
	"""Atualiza os números das estatísticas"""
	diamond_label.text = str(GameManager.total_diamonds)
	record_label.text = str(GameManager.highest_room)

func _on_play_pressed():
	"""Inicia o jogo"""
	print("🎮 Iniciando jogo...")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
