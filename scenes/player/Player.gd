class_name Player
extends CharacterBody2D


const MAX_SPEED := 200.0
const ACCELERATION := 700.0
const DECELERATION := 200.0
const DRAG_STRENGTH := 1.0

const AIR_CONTROL := 0.5
const JUMP_VELOCITY := -400.0
const WALL_JUMP_VELOCITY := 800.0
const COYOTE_TIME := 0.1

var dead = false

var _drag_factor := 0.0

var _air_control_factor := 1.0
var time_in_air := 0.0

var time_since_wall_slide := 0.0
var wall_slide_direction := 0.0
var last_wall_slide_direction := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var movement_direction: float = 0.0


func _ready() -> void:
	_drag_factor = DRAG_STRENGTH * (ACCELERATION / (MAX_SPEED * MAX_SPEED))
	
#	player_idle_state.started_movement_input.connect(fsm.change_state.bind(player_move_state))
	GameEvents.player_died.connect(die)


func _process(delta: float) -> void:
	process_sprite_fx()


func _physics_process(delta: float) -> void:
	if abs(velocity.x) < 0.001 and time_since_wall_slide < COYOTE_TIME:
		var collision := KinematicCollision2D.new()
		test_move(transform, Vector2(last_wall_slide_direction, 0), collision)
		if collision.get_collider():
			velocity.x += last_wall_slide_direction
	
	if is_on_floor():
		_air_control_factor = 1
	else:
		_air_control_factor = AIR_CONTROL
	
	# Add the gravity.
	if not is_on_floor():
		if abs(wall_slide_direction) > 0.5:
			var wall_slide_gravity_amount = clamp(remap(velocity.y,
				0.0, JUMP_VELOCITY, 0.5, 1.0), 0.5, 1.0)
#			print(floor(velocity.y), " gravity: ", wall_slide_gravity_amount)
			velocity.y += gravity * delta * wall_slide_gravity_amount
			
			time_since_wall_slide = 0.0
		else:
			velocity.y += gravity * delta
			time_since_wall_slide += delta
		time_in_air += delta
	else:
		time_in_air = 0
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		print("time in air: ", time_in_air, " time since wall slide: ", time_since_wall_slide)
		if time_in_air < COYOTE_TIME:
			velocity.y = JUMP_VELOCITY
			time_in_air = COYOTE_TIME
		elif time_since_wall_slide < COYOTE_TIME:
			velocity.y = JUMP_VELOCITY
			velocity.x = last_wall_slide_direction * WALL_JUMP_VELOCITY / 2
			time_in_air = COYOTE_TIME
		print("Last wall slid dir: ", last_wall_slide_direction, "Velocityx: ", velocity.x)
	
	# Get the input movement_direction and handle the movement/deceleration.
	movement_direction = Input.get_axis("move_left", "move_right")
	var change_direction_boost := 1.0
	if (movement_direction < 0 and velocity.x > 0) or (
		movement_direction > 0 and velocity.x < 0):
		change_direction_boost = 2
	
	var horizontal_velocity = move_toward(velocity.x, 0,
		_drag_factor * (velocity.x * velocity.x) * _air_control_factor * delta)
	
	if movement_direction != 0.0:
		horizontal_velocity = move_toward(velocity.x, 0,
			_drag_factor * (velocity.x * velocity.x) * _air_control_factor * delta)
		horizontal_velocity = move_toward(horizontal_velocity, movement_direction * MAX_SPEED,
			ACCELERATION * _air_control_factor * change_direction_boost * delta)
	else:
#		horizontal_velocity = move_toward(horizontal_velocity, 0, ACCELERATION * _air_control_factor * delta)
		horizontal_velocity = move_toward(horizontal_velocity, 0, DECELERATION * _air_control_factor * delta)
	
	velocity.x = horizontal_velocity
	if abs(wall_slide_direction) > 0:
		velocity.y = clampf(velocity.y, -1000, 150)
	else:
		velocity.y = clampf(velocity.y, -1000, 300)
	
	if dead:
		velocity.x = 0
	move_and_slide()
	
	if get_slide_collision_count() == 0:
#		last_wall_slide_direction = wall_slide_direction
		wall_slide_direction = 0.0
		return
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
#		print("Collided with: ", collision.get_collider().name)
		if collision.get_collider().is_in_group("Enemy"):
			print("ouch")
		if abs(collision.get_normal().x) > 0.5:
			wall_slide_direction = ceil(collision.get_normal().x)
			last_wall_slide_direction = wall_slide_direction
		else:
			wall_slide_direction = 0.0
		


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_pressed("ui_restart"):
		get_tree().reload_current_scene()


func process_sprite_fx() -> void:
	if abs(wall_slide_direction) < 0.5:
		if abs(velocity.y) > 0:
			sprite.frame = 1
		elif abs(velocity.x) > 0:
			if animation_player.current_animation != "run":
				animation_player.play("run")
		else:
			if animation_player.is_playing():
				animation_player.play("RESET")
			sprite.frame = 0
		
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
	
	else:
		if animation_player.is_playing():
			animation_player.stop()
		if velocity.y != 0:
			sprite.frame = 4
			sprite.flip_h = wall_slide_direction < 0
		else:
			if animation_player.is_playing():
				animation_player.play("RESET")
			sprite.frame = 0


func squished_enemy() -> void:
	velocity.y = JUMP_VELOCITY
	time_in_air = COYOTE_TIME


func die() -> void:
	print("yer dead")
	set_process(false)
	
	dead = true
#	set_physics_process(false)
#	$CollisionShape2D.disabled = true
	set_collision_layer_value(1, false)
	$AnimationPlayer.play("die")
