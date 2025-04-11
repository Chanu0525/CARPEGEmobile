extends MarginContainer
@onready var world_manager = %WorldManager


#move between buttons via arrow keys
func _ready():
	$CenterContainer/VBoxContainer/Start.grab_focus()

#manage starting (maybe trans. to level select later hmmm?)
func _on_start_pressed():
	world_manager.level_end()
	get_tree().change_scene_to_file("res://FINAL GAME SCENES/game.tscn")



#manage quitting
func _on_quit_pressed():
	get_tree().quit()
