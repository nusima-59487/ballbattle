extends Ult

@onready var bijabilli_ball: Ball = $".."

func fire(damage:int, enemy:Ball, kwargs:Dictionary[String, int] = {}) -> void:
	var reset = bijabilli_ball.linear_velocity
	bijabilli_ball.linear_velocity *= 4
	bijabilli_ball.vincibility = false
	await get_tree().create_timer(1.0).timeout
	bijabilli_ball.linear_damp = 9.0
	await get_tree().create_timer(0.5).timeout
	bijabilli_ball.linear_damp = 0.0
	bijabilli_ball.vincibility = true
