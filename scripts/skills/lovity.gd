extends Skill

@export var num: NumberPopup
@export var heal: NumberPopup
@onready var parent: Ball = $".."
@onready var hitray: ShapeCast2D = $ShapeCast2D
var result: Dictionary
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	hitray.global_position = parent.global_position
	hitray.target_position = Vector2.from_angle(parent.linear_velocity.angle()) * 40
# class_specific
@onready var area_2d: Area2D = $Area2D
var basedmg: int; 

func activate(dmg: int, arg: Dictionary[String, int] = {}) -> void:
	area_2d.body_entered.connect(ontouch); 
	basedmg = dmg; 
func deactivate() -> void:
	area_2d.body_entered.disconnect(ontouch); 
func fire() -> void:
	pass

func ontouch(body: Node2D): 
	if body is Ball:
		for i in hitray.get_collision_count():
			if hitray.get_collider(i) == body:
				if body.vincibility:
					var heal_amount := mini(
						basedmg / 2,
						parent.healthComponent.baseHealth - parent.healthComponent.health
					)
					num.visible = true
					
					num.popup(str(basedmg))
					parent.ult_gauge_percentage += absi(int(1.25*basedmg))
					if heal_amount > 0:
						parent.healthComponent.heal(heal_amount)
						if heal:
							heal.visible = true
							heal.popup("+" + str(heal_amount))
				body.healthComponent.damage(basedmg, body.vincibility)
				fired.emit()
				return
