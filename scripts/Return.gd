extends Node2D

@onready var world_manager = %WorldManager

func _on_ready():
	$Timer.start
	


func _on_timer_timeout():
	world_manager.level_end()
