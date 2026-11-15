extends Node2D

@onready var player_slot_1: TextureButton = $PlayerSlot1
@onready var player_slot_2: TextureButton = $PlayerSlot2
@onready var player_slot_3: TextureButton = $PlayerSlot3

@onready var player_slots: Array[TextureButton] = [player_slot_3, player_slot_2, player_slot_1]

@onready var player_ball: Ball = $VerityBall
@onready var enemy_ball: Ball = $BijabilliBall

@onready var player_ult_bar: ProgressBar = $PlayerUltBar
@onready var enemy_ult_bar: ProgressBar = $EnemyUltBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in min(GameInstance.player_balls_lineup.size(), 3): 
		var img = Image.load_from_file("res://assets/" + GameInstance.player_balls_lineup[i] + ".png")
		var img_texture = ImageTexture.create_from_image(img)
		var img1 = Image.load_from_file("res://assets/" + GameInstance.player_balls_lineup[i] + "C.png")
		var img_texture1 = ImageTexture.create_from_image(img1)
		player_slots[i].texture_hover = img_texture1
		player_slots[i].texture_normal = img_texture
		
		
	player_ball.ult_gauge_percentage_update.connect(_on_player_ult_bar_change); 
	enemy_ball.ult_gauge_percentage_update.connect(_on_enemy_ult_bar_change); 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_player_slot_1_pressed() -> void:
	player_slot_2.button_pressed = false
	player_slot_3.button_pressed = false
func _on_player_slot_2_pressed() -> void:
	player_slot_1.button_pressed = false
	player_slot_3.button_pressed = false
func _on_player_slot_3_pressed() -> void:
	player_slot_1.button_pressed = false
	player_slot_2.button_pressed = false
func _on_player_ult_bar_change(new_percentage: int): 
	print("aoeitbdsj")
	player_ult_bar.value = new_percentage
func _on_enemy_ult_bar_change(new_percentage: int): 
	enemy_ult_bar.value = new_percentage
