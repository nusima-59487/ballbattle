extends Node

var player_balls_available: Array[String] = []
var player_balls_lineup: Array[String] = ["bijabilli", "angler","lovity"]

var current_enemy_balls: Array[String]; 

var player_map_pos: Vector2; 
var last_battle_enemy_opponent: String; 
var defeated_opponent_enemies: Array[String];

# Dialogue info for the enemy currently being battled (set by LevelEnemy).
var current_enemy_display_name: String
var current_enemy_defeat_dialogue: Array[String] = []
