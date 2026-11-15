extends Resource
class_name HealthComponent

@export var baseHealth: int = 100: 
	set(value): 
		health_changed.emit(health, value, 0)
		baseHealth = value
@export var health: int = 100: 
	set(value): 
		if value < 0: died.emit()
		else: health_changed.emit(value, baseHealth, value-health)
		health = value

signal health_changed(current: int, base: int, delta: int); 
signal died(); 

func damage(damage_amount: int): 
	health -= damage_amount; 
	if health > 0: 
		health_changed.emit(health, baseHealth, -damage_amount); 
	else: 
		died.emit(); 
		print_debug("I died")
	print_debug("I took damage! ", health, "/", baseHealth)

func heal(heal_amount: int): 
	health += heal_amount; 
	if health > baseHealth: 
		health = baseHealth
	health_changed.emit(health, baseHealth, heal_amount); 
