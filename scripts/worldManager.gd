extends Node2D

@onready var level_trans = $LevelTrans
@export var next_level : PackedScene
@onready var timer = $Timer
@export var level_test = PackedScene

#handles BGM
# @onready var BGM =  %BGM_Manager


func _ready():
	get_tree().paused = true
	await LevelTrans.fade_from_black()
	get_tree().paused = false

func level_end():
	print("level ends")
	# BGM.level_end()
	Engine.time_scale = 0.5
	timer.start()

func _input(event):
	if event.is_action_pressed("Debug"):
		print("DEBUG PRESSED")
		get_tree().change_scene_to_packed(level_test)
# the "Home" key is the debug key

func _on_timer_timeout():
	
	print("world end timer done")
	await LevelTrans.fade_to_black()
	Engine.time_scale = 1
	
	
	if next_level is PackedScene:
		get_tree().change_scene_to_packed(next_level)
	
	else: get_tree().change_scene_to_file("res://scenes/UI/start_menu.tscn")
