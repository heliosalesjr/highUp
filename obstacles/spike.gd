extends ObstacleBase
class_name Spike

# Espinho - obstáculo básico

const SPIKE_WIDTH = 40
const SPIKE_HEIGHT = 20

func setup():
	name = "Spike"
	
	# Visual principal
	var visual = ColorRect.new()
	visual.size = Vector2(SPIKE_WIDTH, SPIKE_HEIGHT)
	visual.color = Color.RED
	visual.position = Vector2(-SPIKE_WIDTH / 2.0, -SPIKE_HEIGHT / 2.0)
	add_child(visual)
	
	# LINHA VERDE NO CENTRO para debug (marca exata do position)
	var center_marker = ColorRect.new()
	center_marker.size = Vector2(2, 30)
	center_marker.color = Color.GREEN
	center_marker.position = Vector2(-1, -15)
	add_child(center_marker)
	
	# Adiciona detalhes visuais (pontinhas do spike)
	for i in range(3):
		var point = ColorRect.new()
		point.size = Vector2(8, 8)
		point.color = Color(0.8, 0, 0)
		point.position = Vector2(-SPIKE_WIDTH / 2.0 + i * 16, -SPIKE_HEIGHT / 2.0 - 4)
		add_child(point)
	
	# Collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(SPIKE_WIDTH, SPIKE_HEIGHT)
	collision.shape = shape
	add_child(collision)

func on_player_hit(player: Node2D):
	print("🔴 Player tocou em SPIKE!")
	player_hit.emit()
