extends Resource
class_name HealthComponent

@export var baseHealth: int = 100: 
	set(value): 
		health_changed.emit(health, baseHealth)
@export var health: int = 100: 
	set(value): 
		health = clampi(value, 1, baseHealth)
		health_changed.emit(health, baseHealth)

signal health_changed(current: int, base: int); 
signal died(); 

func damage(damage_amount: int): 
	health -= damage_amount; 
	if health > 0: 
		health_changed.emit(health, baseHealth); 
	else: 
		died.emit(); 

func heal(heal_amount: int): 
	health += heal_amount; 
	if health > baseHealth: 
		health = baseHealth
	health_changed.emit(health, baseHealth); 
