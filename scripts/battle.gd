extends Node2D

@onready var player_slot_1: TextureButton = $PlayerSlot1
@onready var player_slot_2: TextureButton = $PlayerSlot2
@onready var player_slot_3: TextureButton = $PlayerSlot3

@onready var player_slots: Array[TextureButton] = [player_slot_3, player_slot_2, player_slot_1]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in min(GameInstance.player_balls_lineup.size(), 3): 
		var img = Image.load_from_file("res://assets/" + GameInstance.player_balls_lineup[i] + ".png")
		print(img)
		var img_texture = ImageTexture.create_from_image(img)
		print(img_texture)
		player_slots[i].texture_normal = img_texture
		print(player_slots[i].texture_normal)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
