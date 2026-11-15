@abstract
extends Node
class_name Ult

@abstract func fire(
	base_atk_dmg: int, 
	enemy: Ball,
	modifiers: Dictionary[String, int] = {}
) -> void; 
