extends Ult

@onready var ball: Ball = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func fire(
	base_atk_dmg: int, 
	enemy:Ball,
	modifiers: Dictionary[String, int] = {}
) -> void:
	if ball:
		ball.angular_velocity = 30
		ball.linear_velocity = Vector2.ZERO
		await get_tree().create_timer(1.5).timeout
		ball.linear_velocity = Vector2.from_angle(deg_to_rad(ball.initialAngle)) * ball.speed
		ball.angular_velocity = 6
		
