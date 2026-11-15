extends Skill

@export var num: NumberPopup
@onready var parent: Ball = $"../.."
var result: Dictionary

var basedmg: int;

@onready var area_2d: Area2D = $Area2D

func activate(dmg: int, arg: Dictionary[String, int] = {}) -> void:
	area_2d.body_entered.connect(ontouch); 
	basedmg = dmg; 
func deactivate() -> void:
	area_2d.body_entered.disconnect(ontouch); 
func fire() -> void:
	pass

func ontouch(body: Node2D): 
	if body is Ball and body != parent:
		if body.vincibility:
			num.visible = true
			num.popup(str(basedmg/2))
			parent.ult_gauge_percentage += absi(int(1.25*basedmg))
		body.healthComponent.damage(basedmg/2, body.vincibility); 
		fired.emit()
