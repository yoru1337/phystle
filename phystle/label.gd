extends Label

@export var rotation_speed: float = 5.0
@export var max_angle: float = 5.0 # Maximum tilt in degrees

var time_passed: float = 0.0

func _ready() -> void:
	# Automatically centers the pivot point using the label's size
	pivot_offset = size / 2

func _process(delta: float) -> void:
	# Keep pivot updated in case the text length changes lives count
	pivot_offset = size / 2
	
	time_passed += delta
	rotation_degrees = sin(time_passed * rotation_speed) * max_angle
