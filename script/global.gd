extends Node

# --- DATA NAVIGASI ---
var grave_scene_path : String = "" 
var next_spawn_pos = null
var intro_played : bool = false

# --- DATA PLAYER ---
var player_name : String = "Guest"
var stored_hp : int = -1
var saved_stats : Dictionary = {} 
var saved_inventory : Array = [] 
var saved_buffs : Array = []

# --- DATA LOOT ---
var grave_loot : Array = [] 
var scene_floor_loot : Dictionary = {}
