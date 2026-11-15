extends CharacterBody2D
class_name LevelPlayer


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var is_frozen = false
@onready var cahr: AnimatedSprite2D = $cahr


func _physics_process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var directionx := Input.get_axis("ui_left", "ui_right")
	if directionx and not is_frozen:
		cahr.play("side")
		if directionx > 0:
			cahr.flip_h = false
		else:
			cahr.flip_h = true
		velocity.x = directionx * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	var directiony := Input.get_axis("ui_up", "ui_down")
	if directiony and not is_frozen:
		if directiony < 0:
			cahr.play("up")
		else:
			cahr.play("down")
		velocity.y = directiony * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	if !(directionx or directiony):
		cahr.play("idle")

	move_and_slide()
