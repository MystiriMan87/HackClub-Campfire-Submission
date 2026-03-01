extends CharacterBody2D

const SPEED        = 300.0
const GRAVITY      = 800.0
const TILE_SIZE    = 128
const DIG_DURATION = 0.15

const BODY_SCALE    = Vector2(0.7, 0.7)
const BODY_OFFSET   = Vector2(0.0, 0.0)  
const HEAD_OFFSET   = Vector2(0.0, -15.0)
const ARM_L_OFFSET  = Vector2(-20.0, -5.0)
const ARM_R_OFFSET  = Vector2(20.0, -5.0)
const LEG_OFFSET    = Vector2(0.0, 15.0)

@onready var camera  : Camera2D = $Camera2D
@onready var body    : Sprite2D = $Body
@onready var head    : Sprite2D = $Head
@onready var arm_l   : Sprite2D = $ArmL
@onready var arm_r   : Sprite2D = $ArmR
@onready var leg     : Sprite2D = $Leg
@onready var dig_sound  : AudioStreamPlayer = $DiggingSound
@onready var rock_sound : AudioStreamPlayer = $RockSound

var main_scene : Node
var is_digging  = false
var dig_timer   = 0.0
var facing      = Vector2i(1, 0)

var walk_cycle  = 0.0  
var idle_sway   = 0.0  
var dig_anim    = 0.0   
var land_squash = 1.0  
var was_on_floor = false

# Screen shake
var shake_amount = 0.0
var shake_timer  = 0.0

func _ready():
	main_scene = get_parent()
	

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta
		camera.offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
	else:
		camera.offset = Vector2.ZERO

	_animate_limbs(delta)

func _physics_process(delta):
	var on_floor = is_on_floor()

	if on_floor and not was_on_floor:
		land_squash = 0.6  
	land_squash = lerp(land_squash, 1.0, delta * 12.0)  
	was_on_floor = on_floor

	# Gravity
	if not on_floor:
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
		_flip_all(false)
	elif dir < 0:
		facing = Vector2i(-1, 0)
		_flip_all(true)

	if Input.is_action_just_pressed("ui_accept"):
		_try_dig(facing)
	if Input.is_action_just_pressed("ui_down"):
		_try_dig(Vector2i(0, 1))

	move_and_slide()

func _flip_all(flipped: bool):
	body.flip_h = flipped
	head.flip_h = not flipped
	leg.flip_h  = flipped
	arm_l.flip_h = not flipped
	arm_r.flip_h = flipped

func _animate_limbs(delta):
	var on_floor = is_on_floor()
	var moving   = abs(velocity.x) > 10.0

	if is_digging:
		var dig_dir = 1.0 if facing.x > 0 else -1.0
		arm_l.rotation = lerp(arm_l.rotation, -1.2 * dig_dir, delta * 15.0)
		arm_r.rotation = lerp(arm_r.rotation,  0.4 * dig_dir, delta * 15.0)
		head.rotation  = lerp(head.rotation, 0.1 * dig_dir, delta * 10.0)

	elif moving and on_floor:
		walk_cycle += delta * 10.0
		arm_l.rotation = sin(walk_cycle) * 0.6
		arm_r.rotation = sin(walk_cycle + PI) * 0.6
		head.rotation  = sin(walk_cycle * 0.5) * 0.05 

	elif not on_floor:
		arm_l.rotation = lerp(arm_l.rotation, -0.8, delta * 5.0)
		arm_r.rotation = lerp(arm_r.rotation,  0.8, delta * 5.0)
		head.rotation  = lerp(head.rotation, -0.1, delta * 5.0)

	else:
		# Idle
		idle_sway += delta * 1.5
		arm_l.rotation = lerp(arm_l.rotation, sin(idle_sway) * 0.08, delta * 3.0)
		arm_r.rotation = lerp(arm_r.rotation, sin(idle_sway + PI) * 0.08, delta * 3.0)
		head.rotation  = lerp(head.rotation, sin(idle_sway * 0.7) * 0.03, delta * 3.0)

	leg.rotation = 0.0

	body.scale = Vector2(BODY_SCALE.x * (2.0 - land_squash), BODY_SCALE.y * land_squash)



func _try_dig(direction: Vector2i):
	var player_tile = Vector2i(floori(position.x / TILE_SIZE), floori(position.y / TILE_SIZE))
	var target = player_tile + direction
	var result = main_scene.dig_tile(target)

	if result == "rock":
		if rock_sound.playing:
			rock_sound.stop()
		rock_sound.pitch_scale = randf_range(0.85, 1.15)
		rock_sound.play()
		return

	if result == "empty":
		return
		
	
	if dig_sound.playing:
		dig_sound.stop()
	dig_sound.pitch_scale = randf_range(0.9, 1.1)
	dig_sound.play()

	is_digging = true
	dig_timer  = DIG_DURATION
	dig_anim   = 0.0

	match result:
		"gem", "gold", "fuel":
			if rock_sound.playing:
				rock_sound.stop()
			rock_sound.pitch_scale = randf_range(0.9, 1.1)
			rock_sound.play()
		_:  # dirt
			if dig_sound.playing:
				dig_sound.stop()
			dig_sound.pitch_scale = randf_range(1.3, 1.6)
			dig_sound.play()

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

func _shake_camera(amount: float, duration: float):
	shake_amount = amount
	shake_timer  = duration
