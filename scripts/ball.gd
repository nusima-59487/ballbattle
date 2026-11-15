extends RigidBody2D
class_name Ball

@export var healthComponent: HealthComponent; 
@export var speed: int; 
@export var initialAngle: float = 0; 
@export var angularVelocity: int; 
@export var baseDamage: int; 
@export var ballName: String; 
@export var skill: Skill; 

signal ult_gauge_percentage_update(percentage: int)
var ult_gauge_percentage: int = 0: 
	set(value): 
		ult_gauge_percentage = clampi(value, 0, 100); 
		ult_gauge_percentage_update.emit(ult_gauge_percentage)

@onready var ult: Ult; 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.angular_velocity = angularVelocity; 
	self.linear_velocity = Vector2.from_angle(deg_to_rad(initialAngle)) * speed;
	
	healthComponent.health_changed.connect(_on_health_changed); 
	healthComponent.died.connect(_on_died); 
	
	$HealthLabel.text = str(healthComponent.health) + "/" + str(healthComponent.baseHealth)
	
	print($UltNode)
	print($UltNode is Ult)
	
	if $UltNode is Ult: 
		self.ult = $UltNode
	
	# temp
	if self.skill: 
		self.skill.activate(baseDamage);  
		self.skill.fired.connect(_on_skill_fired)


	
func _on_health_changed(current: int, base: int, delta: int): 
	$HealthLabel.text = str(current) + "/" + str(base)
	if delta < 0: 
		self.ult_gauge_percentage += absi(int(1.25*delta))
func _on_died(): 
	queue_free(); 
func _on_skill_fired(): 
	pass
	
func fire_ult(): 
	print(ult)
	if self.ult && self.ult_gauge_percentage == 100: 
		self.ult.fire(baseDamage)
		self.ult_gauge_percentage = 0
