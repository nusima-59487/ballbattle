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
	if Ball:
		var reset = enemy.linear_velocity
		enemy.linear_damp = 11.0
		ball.baseDamage *= 4
		await get_tree().create_timer(1.5).timeout
		ball.baseDamage /= 4
		enemy.linear_damp = 0.0
		enemy.linear_velocity = reset
		
