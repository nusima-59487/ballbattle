extends Skill

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(self.get_parent())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# class_specific
@onready var area_2d: Area2D = $Area2D
var basedmg: int; 

func activate(dmg: int, arg: Dictionary[String, int] = {}) -> void:
	area_2d.body_entered.connect(ontouch); 
	basedmg = dmg; 
	print("connected!")
func deactivate() -> void:
	area_2d.body_entered.disconnect(ontouch); 
func fire() -> void:
	pass

func ontouch(body: Node2D): 
	print("hi fellow ball")
	if body is Ball: 
		body.healthComponent.damage(basedmg); 
