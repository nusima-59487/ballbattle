class_name NumberPopup extends Node2D

'''
Node2D
-> Label
-> AnimationPlayer

Have an animation that makes it scale up really fast, 
then turn transparent and scale down

If you are going to spawn a lot, create a manager with a pool of numbers!
'''


@export var speed: float = 100
@export var friction: float = 15
var shift_direction: Vector2 = Vector2.ZERO
@onready var ball: Ball = $".."
@onready var label: Label = get_node_or_null("Label") as Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func popup(damage: String, popup_direction: Vector2 = Vector2.ZERO) -> void:
	if label:
		label.text = str(damage)
	global_position = ball.global_position
	modulate = ball.modulate
	animation_player.play("pop")
	await animation_player.animation_finished
	visible = false
	shift_direction += popup_direction


func _process(delta: float) -> void:
	global_position += speed * shift_direction * delta
	speed = max(speed - friction * delta, 0)
