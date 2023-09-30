extends Node2D
# Spawns blocks and enemies etc

@export var terrain_scene: PackedScene

@export var block_scenes: Array[PackedScene]

@export var spawn_locations: Array[Vector2]
var vertical_spawn_offset: float = 0.0

@onready var block_spawn_timer: Timer = $BlockSpawnTimer

@export var camera_move_time: float = 1.0

@export var time_since_camera_move: float = 0.0

@onready var game_position: Node2D = $GamePosition

var last_terrain_height: float = 0.0

# Should probably pick location and block independently,
# then rotate block if it would otherwise go off end of screen

# Ahh we need the camera to follow player vertically, rather than scroll

func _ready() -> void:
#	GameEvents.block_landed.connect(spawn_block)
	pass


func _process(delta: float) -> void:
	time_since_camera_move += delta
	if time_since_camera_move > camera_move_time:
		time_since_camera_move -= camera_move_time
		game_position.position.y -= 1
	
	if last_terrain_height > game_position.position.y:
		spawn_terrain()


func spawn_block() -> void:
	var block_scene = block_scenes.pick_random()
	
	var block_instance = block_scene.instantiate() as Block
	
	var spawn_location = spawn_locations.slice(
		0, spawn_locations.size() + 1 - block_instance.block_unit_width).pick_random()
	
	add_child(block_instance)
	block_instance.position = spawn_location + Vector2(0, vertical_spawn_offset)
	vertical_spawn_offset -= 64


func spawn_terrain() -> void:
	last_terrain_height -= 32
	var terrain = terrain_scene.instantiate()
	$Terrains.add_child(terrain)
	terrain.position.y = last_terrain_height


func _on_block_spawn_timer_timeout() -> void:
	spawn_block()
