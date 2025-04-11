extends Node

var ssCount = 1


func _ready():
	var dir = DirAccess.open("res://assets/screenshots/")
	for n in dir.get_files():
		ssCount += 1


func _input(event):
	if event.is_action_pressed("Screengrab"):
		var viewport = get_viewport()
		var img = viewport.get_texture().get_image()
		img.save_png("res://assets/screenshots/screenshot"+str(ssCount)+".png")
		ssCount += 1
