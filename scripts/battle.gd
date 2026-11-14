extends Node2D

@onready var player_slot_1: TextureButton = $PlayerSlot1
@onready var player_slot_2: TextureButton = $PlayerSlot2
@onready var player_slot_3: TextureButton = $PlayerSlot3

@onready var player_slots: Array[TextureButton] = [player_slot_3, player_slot_2, player_slot_1]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in min(GameInstance.player_balls_lineup.size(), 3): 
		var img = Image.load_from_file("res://assets/" + GameInstance.player_balls_lineup[i] + ".png")
		var img_texture = ImageTexture.create_from_image(img)
		var img1 = Image.load_from_file("res://assets/" + GameInstance.player_balls_lineup[i] + "C.png")
		var img_texture1 = ImageTexture.create_from_image(img1)
		player_slots[i].texture_hover = img_texture1
		player_slots[i].texture_normal = img_texture

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
