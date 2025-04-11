extends Area2D

@onready var timer = $Timer

func _on_body_entered(body):
	print("you died!")
	
	Engine.time_scale = 0.8
	
	#sends signal to player script to killself and fade out
	body.handle_danger()
	await LevelTrans.fade_to_black()
	timer.start()

func _on_timer_timeout():
	Engine.time_scale = 1
	get_tree().reload_current_scene()
	
