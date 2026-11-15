extends Ult

@onready var ball: Ball = $".."
var ball_scene = preload("res://balls/krill_ball.tscn")
# Called when the node enters the scene tree for the first time.


func fire(
	base_atk_dmg: int, 
	enemy:Ball,
	modifiers: Dictionary[String, int] = {}
) -> void:
	var ball_new: Ball = ball_scene.duplicate(true).instantiate()
	ball_new.global_position = Vector2(0,0)
	var new_health = ball.healthComponent.health
	ball_new.healthComponent.health = new_health/2 + 15
	ball.healthComponent.health = new_health/2 + 15
	add_sibling(ball_new)

		
