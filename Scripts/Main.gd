extends Node2D

const COLS = 80
const ROWS = 160
const SURFACE_ROW = 3
const TILE_SIZE = 128 

const TILE_DIRT = Vector2i(6, 0)
const TILE_ROCK = Vector2i(5, 7)
const TILE_GOLD = Vector2i(2, 6)
const TILE_GEM  = Vector2i(2, 8)
const TILE_FUEL = Vector2i(3, 0)
const DirtParticles = preload("res://scenes/DirtParticles.tscn")


@onready var tilemap : TileMapLayer = $TileMapLayer
@onready var ui = $UI

@onready var anim = $AnimatedSprite2D
@onready var dig_sfx = $AudioStreamPlayer 

var main_scene : Node 

func _ready():
	print("TileSet: ", tilemap.tile_set)
	print("TileSet sources: ", tilemap.tile_set.get_source_count() if tilemap.tile_set else "NO TILESET")
	
	generate_world()
	$Player.position = Vector2(COLS * TILE_SIZE / 2.0, SURFACE_ROW * TILE_SIZE - TILE_SIZE)
	ui.start_timer()
	var cells = tilemap.get_used_cells()
	print("Cells placed: ", cells.size())
	if cells.size() > 0:
		print("First cell at: ", cells[0])
		print("Last cell at: ", cells[-1])
	
	var cam = Camera2D.new()
	add_child(cam)
	cam.position = Vector2(COLS * TILE_SIZE / 2.0, SURFACE_ROW * TILE_SIZE)

func generate_world():
	for y in ROWS:
		for x in COLS:
			if y < SURFACE_ROW:
				pass
			elif y == SURFACE_ROW:
				tilemap.set_cell(Vector2i(x, y), 2, TILE_DIRT)
			else:
				var depth = y - SURFACE_ROW
				
				if randf() < 0.015 and depth > 2:
					tilemap.set_cell(Vector2i(x, y), 2, TILE_FUEL)
				elif randf() < 0.05 + depth * 0.003:
					tilemap.set_cell(Vector2i(x, y), 2, TILE_ROCK)
				elif randf() < 0.03 and depth > 15:
					tilemap.set_cell(Vector2i(x, y), 2, TILE_GEM)
				elif randf() < 0.05 and depth > 5:
					tilemap.set_cell(Vector2i(x, y), 2, TILE_GOLD)
				else:
					tilemap.set_cell(Vector2i(x, y), 2, TILE_DIRT)
				


func dig_tile(tile_pos: Vector2i) -> String:
	var cell = tilemap.get_cell_atlas_coords(tile_pos)
	if cell == Vector2i(-1, -1): return "empty"
	if cell == TILE_ROCK:        return "rock"

	var reward = "dirt"
	if cell == TILE_GOLD:   reward = "gold"
	elif cell == TILE_GEM:  reward = "gem"
	elif cell == TILE_FUEL: reward = "fuel"

	_spawn_particles(tile_pos, reward)

	tilemap.erase_cell(tile_pos)
	return reward
	
func _spawn_particles(tile_pos: Vector2i, type: String):
	var particles = DirtParticles.instantiate()
	add_child(particles)
	
	particles.position = Vector2(
		tile_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
		tile_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	)
	
	var color: Color
	match type:
		"gold":  color = Color(1.0, 0.85, 0.0)    # gold yellow
		"gem":   color = Color(0.3, 0.8, 1.0)     # cyan blue
		"fuel":  color = Color(0.2, 0.9, 0.2)     # green
		_:       color = Color(0.55, 0.35, 0.15)  # dirt brown
	
	particles.process_material.color = color
	particles.emitting = true
	
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()
