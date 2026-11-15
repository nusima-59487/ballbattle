extends CPUParticles2D



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	angular_velocity_max = $".".global_rotation
	angular_velocity_min = $".".global_rotation
