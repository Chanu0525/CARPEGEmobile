extends Area2D

@onready var world_manager = %WorldManager



func _on_body_entered(body):
	
	print("exit door entered")
	world_manager.level_end()
