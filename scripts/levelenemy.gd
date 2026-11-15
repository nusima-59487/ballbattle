extends Sprite2D
class_name LevelEnemy

@export var balls_lineup: Array[String] = ["verity"];
@export var move_speed = 10
@export var target_position : Vector2;

@export_group("Dialogue")
## Name shown in the dialogue box. Falls back to the node name if empty.
@export var display_name: String = ""
## Lines said when this enemy spots the player (before the battle).
@export_multiline var intro_dialogue: Array[String] = [
	"Hey! You there!",
	"Your balls look weak. Let's battle!",
]
## Lines said when this enemy is defeated (at the end of the battle).
@export_multiline var defeat_dialogue: Array[String] = [
	"No way... my balls lost?!",
	"Fine. You win this time.",
]

var _triggered := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#if target_position:
		#self.position = self.position.move_toward(target_position, move_speed);
		#if self.position == target_position:
			#print("im here")

func get_speaker_name() -> String:
	return display_name if display_name != "" else str(name)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if _triggered or not body is LevelPlayer:
		return
	_triggered = true
	print("YOU ARE IN BATTLE")
	body.is_frozen = true

	await DialogueBox.show_dialogue(get_tree().current_scene, get_speaker_name(), intro_dialogue).finished

	#self.target_position = body.position
	var move = get_tree().create_tween()
	move.set_trans(Tween.TRANS_CUBIC)
	move.tween_property(self,"global_position", body.global_position - Vector2(0, -25), 1.0)
	await move.finished
	GameInstance.current_enemy_balls = self.balls_lineup
	GameInstance.last_battle_enemy_opponent = self.name
	GameInstance.current_enemy_display_name = get_speaker_name()
	GameInstance.current_enemy_defeat_dialogue = defeat_dialogue
	GameInstance.player_map_pos = body.position
	get_tree().change_scene_to_file("res://main.tscn")
