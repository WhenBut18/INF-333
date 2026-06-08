@tool
extends Area2D

# ==========================================
# CONFIGURACIÓN DEL INSPECTOR
# ==========================================

@export_group("Dimensiones de Muerte")
@export var dimensiones: Vector2 = Vector2(1000, 100):
	set(value):
		dimensiones = value
		_actualizar_dimensiones()

# ==========================================
# FUNCIONES PRINCIPALES
# ==========================================

func _ready() -> void:
	if not is_in_group("trampas"):
		add_to_group("trampas")
		
	_actualizar_dimensiones()

func _actualizar_dimensiones() -> void:
	if not is_inside_tree():
		return
		
	var colision = get_node_or_null("CollisionShape2D")
	
	if colision == null:
		colision = CollisionShape2D.new()
		colision.name = "CollisionShape2D"
		add_child(colision)
		
		if Engine.is_editor_hint() and get_tree().edited_scene_root:
			colision.owner = get_tree().edited_scene_root
			
	if colision.shape == null or not colision.shape is RectangleShape2D:
		colision.shape = RectangleShape2D.new()
		
	# --- AQUÍ ESTÁ LA SOLUCIÓN ---
	# Obligamos a la forma a "hacerse única" clonándose a sí misma. 
	# Así rompemos el vínculo con las otras Killzones clonadas.
	colision.shape = colision.shape.duplicate()
			
	colision.shape.size = dimensiones
