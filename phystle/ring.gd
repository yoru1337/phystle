extends Node2D

@export var max_ai_lives: int = 3
@export var wrestler_scenes: Array[PackedScene] # Drag wrestler1.tscn, wrestler2.tscn, etc. here!

var current_ai_lives: int = 3
var ai_defeated_count: int = 0
var current_ai_node: Node2D = null

@onready var spawn_marker: Marker2D = $SpawnPoint if has_node("SpawnPoint") else null
@onready var spawn_position: Vector2 = spawn_marker.global_position if spawn_marker else Vector2(0, 0)

# Reference to the human player (checks group first, falls back to $wrestler path)
@onready var player_node: Node2D = _find_player()
@onready var player_spawn_pos: Vector2 = player_node.global_position if player_node else Vector2(-150, 0)

@onready var lives_label: Label = $CanvasLayer/LivesLabel if has_node("CanvasLayer/LivesLabel") else null
@onready var score_label: Label = $CanvasLayer/ScoreLabel if has_node("CanvasLayer/ScoreLabel") else null

func _find_player() -> Node2D:
	var p = get_tree().get_first_node_in_group("player")
	if p:
		return p
	if has_node("wrestler"):
		return $wrestler
	return null

func _ready() -> void:
	current_ai_lives = max_ai_lives
	spawn_next_ai()

func spawn_next_ai() -> void:
	if current_ai_node and is_instance_valid(current_ai_node):
		current_ai_node.queue_free()
		
	if wrestler_scenes.size() > 0:
		var index = ai_defeated_count % wrestler_scenes.size()
		var scene_to_spawn = wrestler_scenes[index]
		
		# CRITICAL SAFETY CHECK: Prevents crashing if an Inspector slot is empty or null
		if scene_to_spawn:
			current_ai_node = scene_to_spawn.instantiate() as Node2D
			add_child(current_ai_node)
			# Spawn AI slightly to the right side of the ring
			current_ai_node.global_position = spawn_position + Vector2(150, 0)
		else:
			print("ERROR: Wrestler Scenes array slot ", index, " is empty! Please assign a PackedScene in the Inspector.")
	
	current_ai_lives = max_ai_lives
	update_hud()

# Connected from Area2D signal: body_entered
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Refresh player reference just in case
	if not player_node:
		player_node = _find_player()

	# 1. If the HUMAN PLAYER falls out, bounce them back safely (Infinite player respawns)
	if player_node and (body == player_node or player_node.is_ancestor_of(body)):
		respawn_entity(player_node, player_spawn_pos)
		return

	# 2. If the CURRENT AI WRESTLER falls out, track their 3 lives
	if current_ai_node and (body == current_ai_node or current_ai_node.is_ancestor_of(body)):
		current_ai_lives -= 1
		update_hud()
		
		if current_ai_lives > 0:
			respawn_entity(current_ai_node, spawn_position)
		else:
			ai_defeated_count += 1
			print("AI defeated! Spawning next challenger...")
			# .call_deferred() prevents physics flush crashes
			spawn_next_ai.call_deferred()

func respawn_entity(entity: Node2D, default_spawn: Vector2) -> void:
	if entity and entity.has_node("body"):
		var e_body = entity.get_node("body") as RigidBody2D
		
		var fall_offset = entity.global_position - default_spawn
		entity.global_position = default_spawn
		
		# Kill chaotic momentum
		e_body.linear_velocity = Vector2.ZERO
		e_body.angular_velocity = 0.0
		e_body.rotation = 0.0
		
		# Slingshot back up with massive impulse
		var bounce_x = -sign(fall_offset.x) * 400.0 if abs(fall_offset.x) > 50 else 0.0
		var bounce_impulse = Vector2(bounce_x, -9000.0)
		e_body.apply_central_impulse(bounce_impulse)
		
		# Spin arms on re-entry
		if entity.has_node("arm1") and entity.has_node("arm2"):
			var arm1 = entity.get_node("arm1") as RigidBody2D
			var arm2 = entity.get_node("arm2") as RigidBody2D
			arm1.apply_torque_impulse(5000.0)
			arm2.apply_torque_impulse(-5000.0)

func update_hud() -> void:
	if lives_label:
		lives_label.text = "AI Lives: " + str(current_ai_lives)
	if score_label:
		score_label.text = "Beaten: " + str(ai_defeated_count)
