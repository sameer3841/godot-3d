extends CharacterBody3D

var current_state = player_status.MOVE
enum player_status {MOVE, JUMP, ATTACK}

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

@export var speed := 4.0
@export var gravity := 12.0
@export var jump := 7.0

@onready var anim = $AnimationPlayer
@onready var player_body = $CharacterArmature
@onready var camera = $Camera3D
@onready var sword_collider = $CharacterArmature/Skeleton3D/Weapon_Sword/sword/sword_collider

var camera_offset = Vector3(0, 2.0, -3.0)

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var angular_speed = 10
var movement
var direction


func _adjust_camera_position() -> void:
	var global_camera_offset = player_body.global_transform.basis * camera_offset
	camera.transform.origin = player_body.global_transform.origin + global_camera_offset

func _input(event: InputEvent) -> void:
		if Input.is_action_just_pressed('attack'):
			current_state = player_status.ATTACK
		if Input.is_action_just_pressed("jump"):
			jump_now()
		if Input.is_action_pressed("sprint"):
			speed = 10
			
		else:
			speed = 4
			
	
func _physics_process(delta: float) -> void:
	match current_state:
		player_status.MOVE:
			move(delta)
			t_bob += delta * velocity.length() * float(is_on_floor())
			var current_camera_pos = camera.transform.origin
			var headbob_effect = _headbob(t_bob)
			camera.transform.origin = Vector3(current_camera_pos.x, headbob_effect.y + 1.505, current_camera_pos.z)
			var velocity_clamped = clamp(velocity.length(), 0.5, speed * 2)
			var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
			camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
		player_status.JUMP:
			jump_now()
		player_status.ATTACK:
			sword(delta)
	

func move(delta):
	movement = Input.get_vector("left","right", "up","down")
	direction = (transform.basis * Vector3(movement.x,0,movement.y)).normalized()
	if direction:
		if Input.is_action_pressed("sprint"):
			anim.play("Run")
		else:
			anim.play("Walk")
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		player_body.rotation.y = lerp_angle(player_body.rotation.y, atan2(velocity.x, velocity.z), delta * angular_speed)
	else:
		
		anim.play("Idle")
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	
	

	
	#if velocity.y > 0:
		#anim.play("Jump_Idle")
	#else:
		#anim.play("Jump_Land")
	velocity.y -= gravity * delta
	move_and_slide()

func jump_now():
	velocity.y = jump
	anim.play("Jump")
	await anim.animation_finished
	current_state = player_status.MOVE
	
func sword(delta):
	anim.play("Sword")
	await anim.animation_finished
	current_state = player_status.MOVE

func behavior(delta):
	anim.play("Idle")
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	camera.transform.origin += pos
	return pos
