extends Node

@onready var label = $Sprite2D/MarginContainer/VBoxContainer/Label
@onready var world_manager = %WorldManager
@onready var timer = $Timer
@onready var cut_1_big = $Cut1Big

@export_group("lines")
@export var line1 = "1"
@export var line2 = "2"
@export var line3 = "3"

@export_group ("textures")
@export var t1 = preload("res://assets/sprites/handmade/UI_Elements/cut1.png")
@export var t2 = preload("res://assets/sprites/handmade/UI_Elements/cut2.png")
@export var t3 = preload("res://assets/sprites/handmade/UI_Elements/cut4.png")

var next_line = "cum beast"
var next_tex = t1

var space_pressed = 0

func _ready():
	next_line = line1
	label.text = next_line
	next_line = line2
	cut_1_big.set_texture(next_tex)
	next_tex = t2

func _input(event):
	if event.is_action_pressed("jump"):
		cut_1_big.set_texture(next_tex)
		label.text = next_line
		next_line = line3
		next_tex = t3
		#timer.start()
		space_pressed += 1
		print(space_pressed)
		
		if space_pressed > 2:
			world_manager.level_end()
		else:
			pass
