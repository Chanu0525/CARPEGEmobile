extends Node
@onready var Cutscene = $AnimationPlayer
@onready var world_manager = %WorldManager
@onready var endtime = $Timer



func _on_ready():
		Cutscene.play("CutsceneFinal")
		endtime.start(2)




#func _on_animation_player_animation_finished(CutsceneFinal):

func _on_timer_timeout():
	world_manager.level_end()
