extends Area2D


# Called when the node enters the scene tree for the first time

func _on_body_entered(body):
	if body is Player:
		get_tree().change_scene_to_file("res://assets/scenes/main/Ending.tscn")	
