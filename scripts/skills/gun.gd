extends Skill

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# class_specific
func activate(
	base_atk_dmg: int, 
	modifiers: Dictionary[String, int] = {}
) -> void:
	pass
func deactivate() -> void:
	pass
func fire() -> void:
	pass
