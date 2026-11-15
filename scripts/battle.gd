extends Node2D

@onready var player_slot_1: TextureButton = $PlayerSlot1
@onready var player_slot_2: TextureButton = $PlayerSlot2
@onready var player_slot_3: TextureButton = $PlayerSlot3
@onready var enemy_slot_1: Sprite2D = $EnemySlot1
@onready var enemy_slot_2: Sprite2D = $EnemySlot2
@onready var enemy_slot_3: Sprite2D = $EnemySlot3

var current_enemy_ball_idx: int = 0; 
var current_player_ball_idx: int; 
var player_balls_left: int; 

@onready var player_slots: Array[TextureButton] = [player_slot_1, player_slot_2, player_slot_3]
@onready var enemy_slots: Array[Sprite2D] = [enemy_slot_1, enemy_slot_2, enemy_slot_3]

@onready var battleground: Area2D = $Area2D
var can_spawn = false

@onready var player_ball: Ball
@onready var enemy_ball: Ball

@onready var player_ult_bar: ProgressBar = $PlayerUltBar
@onready var enemy_ult_bar: ProgressBar = $EnemyUltBar



var empty_img = Image.load_from_file("res://assets/empty.png")
var empty_img_texture = ImageTexture.create_from_image(empty_img)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battleground.mouse_entered.connect(spawn)
	battleground.mouse_exited.connect(exit)
	
	player_balls_left = GameInstance.player_balls_lineup.size(); 
	for i in min(GameInstance.player_balls_lineup.size(), 3): 
		var img = Image.load_from_file("res://assets/" + GameInstance.player_balls_lineup[i] + ".png")
		var img_texture = ImageTexture.create_from_image(img)
		player_slots[i].mouse_entered.connect(func() -> void : player_slots[i].modulate = Color(0.355, 0.355, 0.355, 1.0))
		player_slots[i].mouse_exited.connect(func() -> void : player_slots[i].modulate = Color(1.0, 1.0, 1.0, 1.0))
		player_slots[i].texture_normal = img_texture
	for i in min(GameInstance.current_enemy_balls.size(), 3): 
		var img = Image.load_from_file("res://assets/" + GameInstance.current_enemy_balls[i] + ".png")
		var img_texture = ImageTexture.create_from_image(img)
		enemy_slots[i].texture = img_texture
		
	current_enemy_ball_idx = 0; 
	spawn_enemy_ball(current_enemy_ball_idx); 
	

func spawn_enemy_ball(idx: int): 
	if idx >= GameInstance.current_enemy_balls.size(): return; 
	var enemy_ball_tscn = load("res://balls/" + GameInstance.current_enemy_balls[idx] + "_ball.tscn");
	enemy_ball = enemy_ball_tscn.instantiate();
	var spawn_position = Vector2.ZERO;
	enemy_ball.healthComponent = enemy_ball.healthComponent.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	enemy_ball.position = spawn_position;
	enemy_ball.find_child("HealthLabel").modulate = Color(1.0, 0.188, 0.188, 1.0)
	var damage_label := enemy_ball.find_child("Node2D").find_child("Label") as Label
	damage_label.modulate = Color(1.0, 0.188, 0.188, 1.0)
	add_child(enemy_ball)
	enemy_ball.ult_gauge_percentage_update.connect(_on_enemy_ult_bar_change); 
	enemy_ball.die.connect(_on_enemy_ball_die)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE) and player_ball and enemy_ball: 
		player_ball.fire_ult(enemy_ball)
	if enemy_ball and player_ball:
		enemy_ball.fire_ult(player_ball)
	for i in range(0,len(player_slots)):
		if (player_slots[i].button_pressed == true):
			player_slots[i].modulate = Color(0.355, 0.355, 0.355, 1.0)
			if (len(battleground.get_overlapping_bodies()) < 2 and can_spawn):
				var img = Image.load_from_file("res://assets/" + GameInstance.player_balls_lineup[i] + ".png")
				var img_texture = ImageTexture.create_from_image(img)
				if (Input.is_action_just_pressed("click")):
					player_slots[i].button_pressed = false
					player_slots[i].disabled = true
					current_player_ball_idx = i
					var player_ball_tscn = load("res://balls/" + GameInstance.player_balls_lineup[i] + "_ball.tscn");
					player_ball = player_ball_tscn.instantiate();
					var spawn_position = battleground.get_global_mouse_position();
					player_ball.healthComponent = player_ball.healthComponent.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
					player_ball.position = spawn_position;
					add_child(player_ball)
					player_ball.ult_gauge_percentage_update.connect(_on_player_ult_bar_change); 
					player_ball.die.connect(_on_player_ball_die)
		else:
			player_slots[i].modulate = Color(1.0, 0.992, 1.0, 1.0)
		

func spawn() -> void:
	can_spawn = true

func exit() -> void:
	can_spawn = false




func _on_player_slot_3_button_pressed() -> void:
	player_slot_1.button_pressed = false
	player_slot_2.button_pressed = false
func _on_player_slot_2_button_pressed() -> void:
	player_slot_1.button_pressed = false
	player_slot_3.button_pressed = false
func _on_player_slot_1_button_pressed() -> void:
	player_slot_2.button_pressed = false
	player_slot_3.button_pressed = false
	
func _on_player_ult_bar_change(new_percentage: int): 
	player_ult_bar.value = new_percentage
func _on_enemy_ult_bar_change(new_percentage: int): 
	enemy_ult_bar.value = new_percentage

func _on_enemy_ball_die(): 
	enemy_slots[current_enemy_ball_idx].texture = empty_img_texture
	current_enemy_ball_idx += 1; 

	await get_tree().create_timer(1).timeout
	if current_enemy_ball_idx >= GameInstance.current_enemy_balls.size(): 
		# enemy ran out of balls, you win
		print("You win!")
		var mapscene: Node2D = load("res://level.tscn").instantiate(); 
		var e = mapscene.find_child(GameInstance.last_battle_enemy_opponent, false)
		if e: 
			e.queue_free(); 
		
		var player: CharacterBody2D = mapscene.find_child("CharacterBody2D", false)
		player.position = GameInstance.player_map_pos; 
		
		get_tree().call_deferred("change_scene_to_node", mapscene)
	else: 
		spawn_enemy_ball(current_enemy_ball_idx)

func _on_player_ball_die(): 
	#var 
	player_slots[current_player_ball_idx].texture_disabled = empty_img_texture
	player_balls_left -= 1; 
	if player_balls_left == 0: 
		# player ran out of balls, you lose
		print("You blacked out!")
		get_tree().paused = true
		await get_tree().create_timer(0.5).timeout
		await DialogueBox.show_dialogue(self, "", ["You blacked out!"], true).finished
		get_tree().paused = false
		# back to the map's starting point; the enemy stays for a rematch
		get_tree().call_deferred("change_scene_to_file", "res://level.tscn")
