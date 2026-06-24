extends CharacterBody2D

# ==========================================
# ESTADOS Y PARÁMETROS DE JUEGO
# ==========================================

enum Estado { NORMAL, ESTIRANDO, CONTRAYENDO }
var estado_actual = Estado.NORMAL
var posicion_inicial: Vector2

@export_group("Físicas y Movimiento")
@export var velocidad_movimiento: float = 200.0
@export var velocidad_estiramiento: float = 400.0
@export var velocidad_contraccion: float = 800.0
@export var max_estiramiento: float = 300.0
@export var gravedad: float = 980.0

# --- VARIABLES PARA EL MOVIMIENTO TIPO SNAKE ---
var puntos_cuerpo: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var direccion_cabeza: Vector2 = Vector2.ZERO

# ==========================================
# REFERENCIAS A NODOS
# ==========================================
@onready var colision_base = $CollisionShape2D
@onready var sprite_base = $SpriteBase
@onready var sprite_cola = $SpriteCola
@onready var linea = $CuerpoChicle
@onready var cabeza = $CabezaArea
@onready var colision_cabeza = $CabezaArea/CollisionShape2D
@onready var sprite_cabeza = $CabezaArea/SpriteCabeza
@onready var colision_detector_base = get_node_or_null("DetectorPeligroBase/CollisionShape2D")
@onready var anim_player = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	posicion_inicial = global_position
	
	if linea:
		linea.width = 79.0 # Ajusta este número al tamaño real de tu sprite
		
		# 1. ESTO ES CLAVE: Elimina cualquier curva que haga que la línea se encoja en el centro
		linea.width_curve = null 
		
		# 2. Cambiamos SHARP por ROUND. Al ser un "chicle", la esquina redondeada se ve mejor
		# y evita que el motor gráfico rompa los vértices en ángulos de 90 grados.
		linea.joint_mode = Line2D.LINE_JOINT_ROUND 
		
		linea.begin_cap_mode = Line2D.LINE_CAP_NONE
		linea.end_cap_mode = Line2D.LINE_CAP_NONE
		
	_actualizar_visibilidad(false)
	if anim_player:
		anim_player.play("idle")

# ==========================================
# LÓGICA DE FÍSICAS Y ESTADOS
# ==========================================

func _physics_process(delta: float) -> void:
	match estado_actual:
		Estado.NORMAL:
			estado_normal(delta)
		Estado.ESTIRANDO:
			estado_estirando(delta)
		Estado.CONTRAYENDO:
			estado_contrayendo(delta)
			
	actualizar_visuales()

func estado_normal(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravedad * delta
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_movimiento)
		
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"): 
		if is_on_floor() and abs(velocity.x) < 10.0:
			estado_actual = Estado.ESTIRANDO
			velocity = Vector2.ZERO 
			
			# Reiniciamos el cuerpo estilo snake
			puntos_cuerpo = [Vector2.ZERO, Vector2.ZERO]
			direccion_cabeza = Vector2.ZERO
			cabeza.position = Vector2.ZERO
			
			_actualizar_visibilidad(true)

func estado_estirando(delta: float) -> void:
	var input_dir = Vector2.ZERO
	
	# Forzamos direcciones ortogonales (una a la vez) para ángulos rectos
	if Input.is_action_pressed("ui_right"): input_dir = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"): input_dir = Vector2.LEFT
	elif Input.is_action_pressed("ui_down"): input_dir = Vector2.DOWN
	elif Input.is_action_pressed("ui_up"): input_dir = Vector2.UP
	
	if input_dir != Vector2.ZERO:
		if direccion_cabeza == Vector2.ZERO:
			direccion_cabeza = input_dir
		# Si cambiamos de dirección (y no es exactamente la contraria)
		elif input_dir != direccion_cabeza and input_dir != -direccion_cabeza:
			# Creamos una nueva esquina agregando un punto al final
			puntos_cuerpo.append(puntos_cuerpo[-1])
			direccion_cabeza = input_dir

	if direccion_cabeza != Vector2.ZERO:
		var tocando_pared = false
		for body in cabeza.get_overlapping_bodies():
			if body != self: 
				tocando_pared = true
				estado_actual = Estado.CONTRAYENDO
				break
		
		if not tocando_pared:
			puntos_cuerpo[-1] += direccion_cabeza * velocidad_estiramiento * delta
		
		# Calcular longitud total del cuerpo para el límite
		var longitud_total = 0.0
		for i in range(1, puntos_cuerpo.size()):
			longitud_total += puntos_cuerpo[i-1].distance_to(puntos_cuerpo[i])
			
		if longitud_total > max_estiramiento:
			var exceso = longitud_total - max_estiramiento
			puntos_cuerpo[-1] -= direccion_cabeza * exceso # Acortamos el último segmento
			
		cabeza.position = puntos_cuerpo[-1]

	if Input.is_action_just_released("ui_accept"):
		estado_actual = Estado.CONTRAYENDO

func estado_contrayendo(delta: float) -> void:
	if puntos_cuerpo.size() > 1:
		var target_local = puntos_cuerpo[1] # El siguiente punto o esquina
		var distance_to_target = target_local.length()
		var step = velocidad_contraccion * delta
		
		if distance_to_target <= step:
			# Llegamos a la esquina, la base se ajusta
			global_position += target_local
			var diff = target_local
			puntos_cuerpo.remove_at(1) # Borramos la esquina (nos la "comimos")
			
			# Desplazamos todos los puntos para mantenerlos relativos a la nueva posición de la base
			for i in range(1, puntos_cuerpo.size()):
				puntos_cuerpo[i] -= diff
		else:
			# Nos acercamos a la esquina
			var move_vec = target_local.normalized() * step
			global_position += move_vec
			
			for i in range(1, puntos_cuerpo.size()):
				puntos_cuerpo[i] -= move_vec

		cabeza.position = puntos_cuerpo[-1]
		
	# Si ya solo queda la cabeza (se contrajo todo)
	if puntos_cuerpo.size() <= 1:
		puntos_cuerpo = [Vector2.ZERO, Vector2.ZERO]
		cabeza.position = Vector2.ZERO
		direccion_cabeza = Vector2.ZERO # <-- NUEVO: Reseteamos la dirección de la cabeza
		estado_actual = Estado.NORMAL
		_actualizar_visibilidad(false)

func actualizar_visuales() -> void:
	if linea:
		linea.clear_points()
		for p in puntos_cuerpo:
			linea.add_point(p)

	# 2. Rotar la cabeza según la dirección o resetearla
	if cabeza:
		if direccion_cabeza != Vector2.ZERO:
			cabeza.rotation = direccion_cabeza.angle() + (PI/2)
		else:
			cabeza.rotation = 0.0
			
			
func _actualizar_visibilidad(estirando: bool) -> void:
	if sprite_base: sprite_base.visible = not estirando
	if sprite_cabeza: sprite_cabeza.visible = estirando
	if sprite_cola: sprite_cola.visible = estirando
	if linea: linea.visible = estirando

func _on_cabeza_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("trampas") and estado_actual == Estado.ESTIRANDO:
		morir()

func morir() -> void:
	estado_actual = Estado.NORMAL
	velocity = Vector2.ZERO
	direccion_cabeza = Vector2.ZERO
	
	# Limpiar el rastro del chicle si murió estirándose
	puntos_cuerpo = [Vector2.ZERO, Vector2.ZERO]
	if cabeza: cabeza.position = Vector2.ZERO
	_actualizar_visibilidad(false)
	
	# Teletransportar al inicio del nivel
	global_position = posicion_inicial
	
func _on_detector_peligro_base_area_entered(area: Area2D) -> void:
	print("Colisión detectada con: ", area.name)
	if area.is_in_group("trampas"):
		print("MUERTE - Reiniciando posición...")
		morir()
