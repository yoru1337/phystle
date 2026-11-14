extends Node2D

@export var move_force: float = 3000.0
@export var jump_impulse: float = 3500.0
@export var arm_torque: float = 15000.0
@onready var body: RigidBody2D = $body
@onready var arm1: RigidBody2D = $arm1
@onready var arm2: RigidBody2D = $arm2
@onready var floor_ray: RayCast2D = $body/FloorRay if has_node("body/FloorRay") else null

var w_was_pressed: bool = false

func _ready() -> void:
	if floor_ray:
		floor_ray.enabled = true

func _physics_process(_delta: float) -> void:
	# Keeps the raycast pointing straight down into the floor even when the body rolls or falls flat
	if floor_ray:
		floor_ray.global_rotation = 0.0

	var move_dir := 0.0
	if Input.is_key_pressed(KEY_A):
		move_dir -= 1.0
	if Input.is_key_pressed(KEY_D):
		move_dir += 1.0
	body.apply_central_force(Vector2(move_dir * move_force, 0.0))

	var w_pressed = Input.is_key_pressed(KEY_W)
	if w_pressed and not w_was_pressed:
		if floor_ray == null or floor_ray.is_colliding():
			body.apply_central_impulse(Vector2.UP * jump_impulse)
	w_was_pressed = w_pressed

	var spin_dir := 0.0
	if Input.is_key_pressed(KEY_Q):
		spin_dir -= 1.0
	if Input.is_key_pressed(KEY_E):
		spin_dir += 1.0

	if spin_dir != 0.0:
		arm1.apply_torque(spin_dir * arm_torque)
		arm2.apply_torque(spin_dir * arm_torque)

	arm1.angular_velocity = clamp(arm1.angular_velocity, -20.0, 20.0)
	arm2.angular_velocity = clamp(arm2.angular_velocity, -20.0, 20.0)
