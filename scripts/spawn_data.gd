extends Resource
class_name SpawnData

# Informações sobre o que pode spawnar
@export var scene: PackedScene  # A cena do obstáculo/inimigo
@export var spawn_chance: float = 0.5  # 0.0 a 1.0 (50% de chance)
@export var min_room_index: int = 1  # A partir de qual sala pode aparecer
@export var max_per_room: int = 1  # Máximo que pode aparecer na mesma sala
@export var spawn_positions: Array[String] = ["left", "center", "right"]  # Onde pode spawnar

# Tipos de elemento
enum ElementType { OBSTACLE, ENEMY, TRAP, PLATFORM }
@export var element_type: ElementType = ElementType.OBSTACLE
