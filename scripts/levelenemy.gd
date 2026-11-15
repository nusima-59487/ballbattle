extends Sprite2D
class_name LevelEnemy

@export var balls_lineup: Array[String] = ["verity"]; 
@export var move_speed = 10
@export var target_position : Vector2; 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#if target_position: 
		#self.position = self.position.move_toward(target_position, move_speed); 
		#if self.position == target_position: 
			#print("im here")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is LevelPlayer: 
		print("YOU ARE IN BATTLE")
		body.is_frozen = true
		#self.target_position = body.position
		var move = get_tree().create_tween()
		move.set_trans(Tween.TRANS_CUBIC)
		move.tween_property(self,"global_position", body.global_position, 1.0)
		await move.finished
		GameInstance.current_enemy_balls = self.balls_lineup
		GameInstance.last_battle_enemy_opponent = self.name
		get_tree().change_scene_to_file("res://main.tscn")
