# mist_indicator.gd
extends Control

@onready var progress_bar = $HBoxContainer/ProgressBar

func _ready():
	# Conecta ao sinal do GameManager
	GameManager.mist_mode_changed.connect(_on_mist_mode_changed)

	# Começa invisível
	visible = false
	print("🌫️ Mist indicator ready!")

func _process(_delta):
	# Atualiza a barra de progresso do mist
	if GameManager.mist_mode_active and progress_bar:
		var progress = GameManager.get_mist_progress()
		progress_bar.value = progress

func _on_mist_mode_changed(is_active: bool):
	"""Chamado quando o modo mist é ativado/desativado"""
	visible = is_active

	if is_active:
		print("🌫️ Mist indicator VISÍVEL!")
	else:
		print("🌫️ Mist indicator OCULTO!")
