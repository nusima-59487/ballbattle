extends Ult

@onready var ball: Ball = $".."
@onready var sword: Skill = $"../sword"



func fire(
	base_atk_dmg: int, 
	enemy:Ball,
	modifiers: Dictionary[String, int] = {}
) -> void:
	if Ball:
		var scale = get_tree().create_tween()
		scale.set_ease(Tween.EASE_IN)
		scale.tween_property(sword, "global_scale", Vector2(2,2), 0.4)
		await get_tree().create_timer(4.3).timeout
		var scale_back = get_tree().create_tween()
		scale_back.set_ease(Tween.EASE_IN)
		scale_back.tween_property(sword, "global_scale", Vector2(1,1), 0.4)
		
