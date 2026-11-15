extends Resource
class_name HealthComponent


@export var baseHealth: int = 100: 
	set(value): 
		health_changed.emit(health, value, 0)
		baseHealth = value
		if health > baseHealth: 
			health = baseHealth
@export var health: int = 100: 
	set(value): 
		if value < 0: died.emit()
		else: health_changed.emit(value, baseHealth, value-health)
		health = value

signal health_changed(current: int, base: int, delta: int); 
signal died(); 

func damage(damage_amount: int, vincible:bool) -> void: 
	if vincible:
		health -= damage_amount; 
		if health > 0: 
			health_changed.emit(health, baseHealth, -damage_amount); 
		else: 
			died.emit(); 
	else:
		pass

func heal(heal_amount: int) -> void: 
	health += heal_amount; 
	if health > baseHealth: 
		health = baseHealth
	health_changed.emit(health, baseHealth, heal_amount); 
	
func _init(health: int = 100, baseHealth: int = 100) -> void:
	self.baseHealth = baseHealth
	self.health = health
