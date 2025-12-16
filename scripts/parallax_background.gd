# parallax_background.gd
# Sistema de Parallax com 4 camadas para movimento vertical
extends Node2D

const SCREEN_WIDTH = 360
const SCREEN_HEIGHT = 640

# Dimensões de cada camada (altura que será repetida)
const LAYER1_HEIGHT = 1280  # Céu - repete a cada 1280px
const LAYER2_HEIGHT = 640   # Árvores distantes - repete a cada 640px
const LAYER3_HEIGHT = 480   # Árvores médias - repete a cada 480px
const LAYER4_HEIGHT = 240   # Primeiro plano - repete a cada 240px

# Velocidades de parallax (motion_scale.y)
const LAYER1_SPEED = 0.1   # Céu - quase não se move (10%)
const LAYER2_SPEED = 0.3   # Fundo - move 30%
const LAYER3_SPEED = 0.6   # Meio - move 60%
const LAYER4_SPEED = 0.85  # Frente - move 85%

# Cores placeholder para cada camada
const LAYER1_COLOR = Color(0.53, 0.81, 0.92)  # Céu azul claro #87CEEB
const LAYER2_COLOR = Color(0.36, 0.54, 0.40)  # Verde distante #5D8A66
const LAYER3_COLOR = Color(0.29, 0.42, 0.31)  # Verde médio #4A6B4E
const LAYER4_COLOR = Color(0.24, 0.35, 0.25, 0.7)  # Verde escuro semi-transparente #3D5A3F

@onready var layer1: Parallax2D = $Layer1_Sky
@onready var layer2: Parallax2D = $Layer2_FarTrees
@onready var layer3: Parallax2D = $Layer3_MidTrees
@onready var layer4: Parallax2D = $Layer4_CloseLeaves

func _ready():
	print("🎨 Parallax Background inicializado")
	setup_layers()

func setup_layers():
	"""Configura todas as camadas de parallax"""

	# Layer 1 - Céu (Fundo) - z_index mais baixo
	if layer1:
		setup_layer(layer1, LAYER1_SPEED, LAYER1_HEIGHT, LAYER1_COLOR, "Sky", -40)

	# Layer 2 - Árvores Distantes
	if layer2:
		setup_layer(layer2, LAYER2_SPEED, LAYER2_HEIGHT, LAYER2_COLOR, "Far Trees", -30)

	# Layer 3 - Árvores Médias
	if layer3:
		setup_layer(layer3, LAYER3_SPEED, LAYER3_HEIGHT, LAYER3_COLOR, "Mid Trees", -20)

	# Layer 4 - Primeiro Plano - z_index mais alto (mas ainda atrás do jogo)
	if layer4:
		setup_layer(layer4, LAYER4_SPEED, LAYER4_HEIGHT, LAYER4_COLOR, "Close Leaves", -10)

func setup_layer(layer: Parallax2D, speed: float, height: int, color: Color, layer_name: String, z_idx: int):
	"""Configura uma camada individual de parallax"""

	# Configurações de parallax
	layer.scroll_scale = Vector2(1.0, speed)
	layer.repeat_size = Vector2(0, height)
	layer.repeat_times = 20  # Repete muitas vezes para cobrir toda a subida

	# Cria sprite placeholder se não existir textura
	var sprite = layer.get_node_or_null("Sprite2D")
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		layer.add_child(sprite)

	# Define o z_index da camada
	layer.z_index = z_idx

	# Se não tem textura, cria padrão visual placeholder
	if not sprite.texture:
		var placeholder_container = sprite.get_node_or_null("PlaceholderContainer")
		if not placeholder_container:
			placeholder_container = Node2D.new()
			placeholder_container.name = "PlaceholderContainer"
			sprite.add_child(placeholder_container)

			# Cria padrão visual único para cada camada
			create_placeholder_pattern(placeholder_container, height, color, layer_name)
			print("  ✓ ", layer_name, " configurado (placeholder: ", SCREEN_WIDTH, "x", height, ", speed: ", speed, "x, z_index: ", z_idx, ")")

	sprite.centered = false

func create_placeholder_pattern(container: Node2D, height: int, color: Color, layer_name: String):
	"""Cria padrão visual para identificar cada camada"""

	if "Sky" in layer_name:
		# Layer 1 - Céu: Fundo sólido + faixas horizontais
		var bg = ColorRect.new()
		bg.size = Vector2(SCREEN_WIDTH, height)
		bg.color = color
		container.add_child(bg)

		# Adiciona nuvens/faixas claras
		for i in range(int(height / 200)):
			var stripe = ColorRect.new()
			stripe.size = Vector2(SCREEN_WIDTH, 30)
			stripe.position = Vector2(0, i * 200 + 50)
			stripe.color = Color(1, 1, 1, 0.2)  # Branco semi-transparente
			container.add_child(stripe)

	elif "Far" in layer_name:
		# Layer 2 - Árvores distantes: Triângulos/montanhas
		for i in range(int(height / 150)):
			var triangle_y = i * 150
			# Triângulo simples (simulando montanha/árvore)
			var poly = Polygon2D.new()
			poly.polygon = PackedVector2Array([
				Vector2(50, triangle_y + 100),
				Vector2(150, triangle_y + 20),
				Vector2(250, triangle_y + 100)
			])
			poly.color = color
			container.add_child(poly)

			# Outro triângulo deslocado
			var poly2 = Polygon2D.new()
			poly2.polygon = PackedVector2Array([
				Vector2(200, triangle_y + 120),
				Vector2(280, triangle_y + 40),
				Vector2(360, triangle_y + 120)
			])
			poly2.color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8)
			container.add_child(poly2)

	elif "Mid" in layer_name:
		# Layer 3 - Árvores médias: Retângulos verticais (troncos)
		for i in range(int(height / 100)):
			var trunk_y = i * 100

			# Tronco esquerdo
			var trunk1 = ColorRect.new()
			trunk1.size = Vector2(15, 80)
			trunk1.position = Vector2(80, trunk_y + 10)
			trunk1.color = color
			container.add_child(trunk1)

			# Tronco direito
			var trunk2 = ColorRect.new()
			trunk2.size = Vector2(15, 60)
			trunk2.position = Vector2(280, trunk_y + 25)
			trunk2.color = color
			container.add_child(trunk2)

	elif "Close" in layer_name:
		# Layer 4 - Primeiro plano: Círculos/folhas esparsas
		for i in range(int(height / 60)):
			var leaf_y = i * 60

			# Folha esquerda
			var circle1 = draw_circle_placeholder(Vector2(40, leaf_y + 20), 25, color)
			container.add_child(circle1)

			# Folha direita
			var circle2 = draw_circle_placeholder(Vector2(320, leaf_y + 35), 20, color)
			container.add_child(circle2)

func draw_circle_placeholder(pos: Vector2, radius: float, color: Color) -> Polygon2D:
	"""Desenha um círculo usando Polygon2D"""
	var circle = Polygon2D.new()
	var points = PackedVector2Array()
	var segments = 16

	for i in range(segments):
		var angle = (i / float(segments)) * TAU
		points.append(pos + Vector2(cos(angle), sin(angle)) * radius)

	circle.polygon = points
	circle.color = color
	return circle

func load_texture(layer_index: int, texture_path: String):
	"""
	Carrega uma textura real para substituir o placeholder

	Exemplo de uso:
		parallax_bg.load_texture(1, "res://assets/parallax/layer1_sky.png")
	"""
	var layers = [layer1, layer2, layer3, layer4]

	if layer_index < 1 or layer_index > 4:
		print("❌ Índice de camada inválido: ", layer_index, " (use 1-4)")
		return

	var layer = layers[layer_index - 1]
	if not layer:
		print("❌ Camada ", layer_index, " não encontrada")
		return

	var texture = load(texture_path)
	if not texture:
		print("❌ Falha ao carregar textura: ", texture_path)
		return

	var sprite = layer.get_node_or_null("Sprite2D")
	if sprite:
		sprite.texture = texture

		# Remove placeholder se existir
		var placeholder = sprite.get_node_or_null("Placeholder")
		if placeholder:
			placeholder.queue_free()

		print("✅ Textura carregada na camada ", layer_index, ": ", texture_path)
