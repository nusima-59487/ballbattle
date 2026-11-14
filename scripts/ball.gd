extends RigidBody2D
class_name Ball

@export var healthComponent: HealthComponent; 

## d
@export var speed: int; 
@export var angularVelocity: int; 
@export var baseDamage: int; 
@export var ballName: String; 
@export var skill: Skill; 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.angular_velocity = angularVelocity; 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
