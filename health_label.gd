extends RichTextLabel

@onready var ball: Ball = $".."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	global_position = ball.global_position + Vector2(-18,-14)
