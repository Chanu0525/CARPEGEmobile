extends TouchScreenButton

func _ready():
	# 터치 시그널 연결
	pressed.connect(_on_pressed)

func _on_pressed():
	get_tree().change_scene_to_file("res://FINAL GAME SCENES/game.tscn")  # 경로 수정 필수!
