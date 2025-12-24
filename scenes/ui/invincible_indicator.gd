# invincible_indicator.gd
extends Control

@onready var progress_bar = $HBoxContainer/ProgressBar

func _ready():
	# Conecta ao sinal do GameManager
	GameManager.invincible_mode_changed.connect(_on_invincible_mode_changed)

	# Começa invisível
	visible = false
	print("💪 Invincible indicator ready!")

func _process(_delta):
	# Atualiza a barra de progresso do invincible
	if GameManager.invincible_mode_active and progress_bar:
		var progress = GameManager.get_invincible_progress()
		progress_bar.value = progress

func _on_invincible_mode_changed(is_active: bool):
	"""Chamado quando o modo invincible é ativado/desativado"""
	visible = is_active

	if is_active:
		print("💪 Invincible indicator VISÍVEL!")
	else:
		print("💪 Invincible indicator OCULTO!")
