@abstract
extends Node2D
class_name Skill

@abstract func activate(
	base_atk_dmg: int, 
	modifiers: Dictionary[String, int] = {}
) -> void; 

@abstract func deactivate() -> void; 

@abstract func fire() -> void; 
