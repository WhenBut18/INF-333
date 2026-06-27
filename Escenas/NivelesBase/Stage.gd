extends Node2D


@onready var gameplay_music = $Music

func _ready():
	gameplay_music.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
