extends RigidBody2D
class_name Ball

@export var healthComponent: HealthComponent; 
@export var speed: int; 
@export var initialAngle: float = 0; 
@export var angularVelocity: int; 
@export var baseDamage: int; 
@export var ballName: String; 
@export var skill: Skill; 
@export var additional_skill: Skill;

var is_dead = false; 

var vincibility = true

signal ult_gauge_percentage_update(percentage: int)
signal die(); 

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
	for active_skill in [skill, additional_skill]:
		if active_skill:
			active_skill.activate(baseDamage)
			active_skill.fired.connect(_on_skill_fired)


	
func _on_health_changed(current: int, base: int, _delta: int): 
	$HealthLabel.text = str(current) + "/" + str(base)
	
func _on_died(): 
	if not is_dead: 
		is_dead = true
		die.emit()
		queue_free(); 
func _on_skill_fired(): 
	pass
	
func fire_ult(enemy:Ball = null): 
	print(ult)
	if self.ult && self.ult_gauge_percentage == 100: 
		self.ult.fire(baseDamage, enemy)
		self.ult_gauge_percentage = 0
