extends RigidBody2D
class_name Ball

@export var healthComponent: HealthComponent; 
@export var speed: int; 
@export var initialAngle: float = 0; 
@export var angularVelocity: int; 
@export var baseDamage: int; 
@export var ballName: String; 
@export var skill: Skill; 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.angular_velocity = angularVelocity; 
	self.linear_velocity = Vector2.from_angle(deg_to_rad(initialAngle)) * speed;
	
	healthComponent.health_changed.connect(_on_health_changed); 
	healthComponent.died.connect(_on_died); 
	
	$HealthLabel.text = str(healthComponent.health) + "/" + str(healthComponent.baseHealth)
	
	# temp
	if self.skill: 
		print("hi")
		self.skill.activate(baseDamage);  

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_health_changed(current: int, base: int): 
	$HealthLabel.text = str(current) + "/" + str(base)
func _on_died(): 
	queue_free(); 
