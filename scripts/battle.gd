extends Node2D

@onready var player_slot_1: TextureButton = $PlayerSlot1
@onready var player_slot_2: TextureButton = $PlayerSlot2
@onready var player_slot_3: TextureButton = $PlayerSlot3

@onready var player_slots: Array[TextureButton] = [player_slot_1, player_slot_2, player_slot_3]
@onready var battleground: Area2D = $Area2D
var can_spawn = false

@onready var player_ball: Ball = $VerityBall
@onready var enemy_ball: Ball = $BijabilliBall

@onready var player_ult_bar: ProgressBar = $PlayerUltBar
@onready var enemy_ult_bar: ProgressBar = $EnemyUltBar



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battleground.mouse_entered.connect(spawn)
	battleground.mouse_exited.connect(exit)
	#player_ball.ult_gauge_percentage_update.connect(_on_player_ult_bar_change); 
	#enemy_ball.ult_gauge_percentage_update.connect(_on_enemy_ult_bar_change); 
	for i in min(GameInstance.player_balls_lineup.size(), 3): 
		var img = Image.load_from_file("res://assets/" + GameInstance.player_balls_lineup[i] + ".png")
		var img_texture = ImageTexture.create_from_image(img)
		var img1 = Image.load_from_file("res://assets/" + GameInstance.player_balls_lineup[i] + "C.png")
		var img_texture1 = ImageTexture.create_from_image(img1)
		player_slots[i].texture_hover = img_texture1
		player_slots[i].texture_normal = img_texture

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE) and player_ball: 
		player_ball.fire_ult()
	print(can_spawn)
	if can_spawn:
		for i in range(0,len(player_slots)):
			if player_slots[i].button_pressed == true and Input.is_action_just_pressed("click") and len(battleground.get_overlapping_bodies()) < 2:
				player_slots[i].button_pressed = false
				player_slots[i].disabled = true
				var player_ball_tscn = load("res://balls/" + GameInstance.player_balls_lineup[i] + "_ball.tscn");
				var player_ball = player_ball_tscn.instantiate() as Ball;
				var spawn_position = battleground.get_global_mouse_position();
				player_ball.healthComponent = player_ball.healthComponent.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
				player_ball.position = spawn_position;
				print(GameInstance.player_balls_lineup[i], " sonned ")
				add_child(player_ball)
		

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
