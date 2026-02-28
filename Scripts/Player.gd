extends CharacterBody2D

const SPEED = 300.0
const GRAVITY = 1200.0
const TILE_SIZE = 128
const DIG_DURATION = 0.4

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var main_scene: Node
var is_digging = false
var dig_timer = 0.0
var facing = Vector2i(1, 0)  

func _ready():
	main_scene = get_parent()

func _physics_process(delta):
	if is_digging:
		dig_timer -= delta
		if dig_timer <= 0:
			is_digging = false
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	
	if is_digging:
		dig_timer -= delta
		if dig_timer <= 0:
			is_digging = false
		velocity.x = 0.0
		move_and_slide()
		return
		
	var dir = Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * SPEED

	if dir > 0:
		facing = Vector2i(1, 0)
		anim.flip_h = false
	elif dir < 0:
		facing = Vector2i(-1, 0)
		anim.flip_h = true

	if not is_on_floor():
		anim.play("idle")
	elif dir != 0:
		anim.play("walk")
	else:
		anim.play("idle")

	if Input.is_action_just_pressed("ui_accept"):
		_try_dig(facing)
	if Input.is_action_just_pressed("ui_down"):
		_try_dig(Vector2i(0, 1))

	move_and_slide()

func _try_dig(direction: Vector2i):
	var player_tile = Vector2i(
		floori(position.x / TILE_SIZE),
		floori(position.y / TILE_SIZE)
	)
	var target = player_tile + direction
	var result = main_scene.dig_tile(target)

	if result == "empty" or result == "rock":
		return

	is_digging = true
	dig_timer = DIG_DURATION
	anim.play("dig")

	var depth = player_tile.y - main_scene.SURFACE_ROW
	main_scene.ui.update_depth(depth)

	if result == "gold":
		main_scene.ui.add_score(50, "gold")
	elif result == "gem":
		main_scene.ui.add_score(200, "gem")
	elif result == "fuel":
		main_scene.ui.add_fuel(40.0) 
	else:
		main_scene.ui.add_score(1, "dirt") 
