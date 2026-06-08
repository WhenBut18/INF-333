@tool
extends StaticBody2D

# Variables que aparecerán en el Inspector
@export var tamano_bloque: Vector2 = Vector2(64, 64):
	set(value):
		tamano_bloque = value
		_actualizar_bloque()

@export var textura_bloque: Texture2D:
	set(value):
		textura_bloque = value
		_actualizar_bloque()

@onready var sprite: Sprite2D = $Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

func _ready():
	# Nos aseguramos de que cada bloque tenga su propia caja de colisión independiente
	if colision.shape == null:
		colision.shape = RectangleShape2D.new()
	else:
		colision.shape = colision.shape.duplicate()
	
	_actualizar_bloque()

func _actualizar_bloque():
	# Evitamos errores antes de que el árbol de nodos cargue completamente
	if not is_inside_tree() or sprite == null or colision == null:
		return
		
	# 1. Actualizar la textura
	if textura_bloque != null:
		sprite.texture = textura_bloque
		
	# 2. Configurar el Sprite para que se repita como un patrón en lugar de estirarse
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, tamano_bloque)
	
	# 3. Actualizar el tamaño de la caja de colisión física
	if colision.shape is RectangleShape2D:
		colision.shape.size = tamano_bloque
