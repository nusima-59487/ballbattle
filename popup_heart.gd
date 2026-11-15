extends NumberPopup

'''
Node2D
-> Label
-> AnimationPlayer

Have an animation that makes it scale up really fast, 
then turn transparent and scale down

If you are going to spawn a lot, create a manager with a pool of numbers!
'''




func popup(damage: String, popup_direction: Vector2 = Vector2.ZERO) -> void:
	global_position = ball.global_position - Vector2(30,30)
	modulate = ball.modulate
	animation_player.play("pop")
	await animation_player.animation_finished
	visible = false
	shift_direction += popup_direction


func _process(delta: float) -> void:
	global_position += speed * shift_direction * delta
	speed = max(speed - friction * delta, 0)
