extends Node2D

@export var move_force: float = 3000.0
@export var jump_impulse: float = 3500.0
@export var arm_torque: float = 15000.0

@onready var body: RigidBody2D = $body if has_node("body") else null
@onready var arm1: RigidBody2D = $arm1 if has_node("arm1") else null
@onready var arm2: RigidBody2D = $arm2 if has_node("arm2") else null
@onready var floor_ray: RayCast2D = $body/FloorRay if has_node("body/FloorRay") else null

var jump_cooldown: float = 0.0

func _ready() -> void:
	if not body:
		print("ERROR: AI script cannot find $body node! Check your scene tree structure.")
	if floor_ray:
		floor_ray.enabled = true
	randomize()

func _physics_process(delta: float) -> void:
	if not body:
		return
		
	# CRITICAL: Wake up the rigid body so forces actually move it and it doesn't flop
	body.sleeping = false

	# Keep raycast pointing straight down
	if floor_ray:
		floor_ray.global_rotation = 0.0

	# --- 1. TRACK PLAYER (Exact same logic as player's A/D keys) ---
	var move_dir := 0.0
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var target_x = player.global_position.x
		if player.has_node("body"):
			target_x = player.get_node("body").global_position.x
			
		if target_x > body.global_position.x + 15.0:
			move_dir = 1.0  # Walk/Push Right toward player
		elif target_x < body.global_position.x - 15.0:
			move_dir = -1.0 # Walk/Push Left toward player

	body.apply_central_force(Vector2(move_dir * move_force, 0.0))

	# --- 2. JUMP LOGIC (Exact same logic as player's W key) ---
	jump_cooldown -= delta
	if jump_cooldown <= 0.0:
		if floor_ray == null or floor_ray.is_colliding():
			if randf() > 0.4:
				body.apply_central_impulse(Vector2.UP * jump_impulse)
				jump_cooldown = randf_range(1.0, 2.2)

	# --- 3. ARM SWINGING (Active brawling) ---
	if arm1 and arm2:
		var spin_dir = sin(Time.get_ticks_msec() * 0.01)
		arm1.apply_torque(spin_dir * arm_torque)
		arm2.apply_torque(-spin_dir * arm_torque)

		arm1.angular_velocity = clamp(arm1.angular_velocity, -20.0, 20.0)
		arm2.angular_velocity = clamp(arm2.angular_velocity, -20.0, 20.0)
