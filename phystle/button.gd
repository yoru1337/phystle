extends Button

func _ready() -> void:
	# Connects the button's pressed signal automatically via code
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Replace the path with the exact location of your ring.tscn file
	get_tree().change_scene_to_file("res://ring.tscn")
