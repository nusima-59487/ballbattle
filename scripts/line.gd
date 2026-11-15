extends Line2D

@onready var spring: DampedSpringJoint2D = $"../DampedSpringJoint2D"
@onready var hook: RigidBody2D = $"../hook"

func _process(delta: float) -> void:
	if spring and hook:
		points = PackedVector2Array([
			to_local(spring.global_position),
			to_local(hook.global_position)
		])
