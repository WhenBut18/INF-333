extends Area2D

@export var aumento_estiramiento: float = 300.0
@export var multiplicador_escala := 1.15

func _on_area_entered(area):
	print("Collected by:", area.name)
	if area.name == "CabezaArea":
		var player = area.get_parent()
		player.recoger_chicle(aumento_estiramiento, multiplicador_escala)
		queue_free()
