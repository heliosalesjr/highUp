# hud.gd
extends CanvasLayer

@onready var rooms_label = $ScoreContainer/RoomsLabel
@onready var diamonds_label = $ScoreContainer/DiamondsLabel
@onready var heart1 = $HeartsContainer/Heart1
@onready var heart2 = $HeartsContainer/Heart2
@onready var heart3 = $HeartsContainer/Heart3

# Preload das texturas dos corações
var heart_empty_texture = preload("res://assets/heart_empty.png")  # Ajuste o caminho
var heart_full_texture = preload("res://assets/heart_full.png")    # Ajuste o caminho

# Fog overlay
var mist_overlay: ColorRect = null

# Mist indicator (cena separada)
var mist_indicator: Control = null
var mist_indicator_scene = preload("res://scenes/ui/mist_indicator.tscn")

func _ready():
	# Conecta aos sinais do GameManager
	GameManager.rooms_changed.connect(_on_rooms_changed)
	GameManager.diamonds_changed.connect(_on_diamonds_changed)
	GameManager.hearts_changed.connect(_on_hearts_changed)  # ← NOVO
	GameManager.mist_mode_changed.connect(_on_mist_mode_changed)

	# Cria o overlay de neblina
	create_mist_overlay()

	# Instancia a cena do indicador de mist
	mist_indicator = mist_indicator_scene.instantiate()
	mist_indicator.position = Vector2(80, 10)  # Posição inicial (pode ser ajustada no editor depois)
	add_child(mist_indicator)

	# Atualiza valores iniciais
	_on_rooms_changed(GameManager.rooms_count)
	_on_diamonds_changed(GameManager.diamonds_count)
	_on_hearts_changed(GameManager.filled_hearts)  # ← NOVO

func _on_rooms_changed(value: int):
	rooms_label.text = "Rooms: " + str(value)

func _on_diamonds_changed(value: int):
	diamonds_label.text = "Diamonds: " + str(value)

func _on_hearts_changed(filled_count: int):
	"""Atualiza a aparência dos corações"""
	# Array com os 3 corações
	var hearts = [heart1, heart2, heart3]

	# Atualiza cada coração
	for i in range(3):
		if i < filled_count:
			hearts[i].texture = heart_full_texture  # Preenchido
		else:
			hearts[i].texture = heart_empty_texture  # Vazio

	print("💖 HUD atualizada: ", filled_count, " corações cheios")

func create_mist_overlay():
	"""Cria o overlay de neblina (fog) que cobre a tela"""
	mist_overlay = ColorRect.new()
	mist_overlay.name = "MistOverlay"

	# Branco com 50% de opacidade
	mist_overlay.color = Color(1.0, 1.0, 1.0, 0.5)

	# Cobre toda a tela
	mist_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Começa invisível
	mist_overlay.visible = false

	# Z-index alto para ficar acima de tudo (mas abaixo do HUD)
	mist_overlay.z_index = 100

	# Mouse filter passthrough para não bloquear cliques
	mist_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(mist_overlay)
	print("🌫️ Mist overlay criado!")

func _on_mist_mode_changed(is_active: bool):
	"""Chamado quando o modo mist é ativado/desativado"""
	if mist_overlay:
		mist_overlay.visible = is_active

		if is_active:
			print("🌫️ Neblina VISÍVEL!")
		else:
			print("🌫️ Neblina OCULTA!")

	# O indicador se mostra/esconde sozinho (veja mist_indicator.gd)
