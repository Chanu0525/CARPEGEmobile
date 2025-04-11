extends Node

@onready var MusicMan = $In_Or_Out
@onready var ASP = $AudioStreamPlayer2D
@onready var WM = %WorldManager



func level_end():
	print("fade out recieved")
	fade_out()

func _on_audio_stream_player_2d_ready():
	fade_in()



func _on_animation_player_ready():
	pass


func fade_out():
	$In_Or_Out.play("audio_out")

func fade_in():
	$In_Or_Out.play("audio_in")
