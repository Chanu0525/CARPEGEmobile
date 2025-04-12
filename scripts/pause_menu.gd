extends CanvasLayer

# 씬이 로드될 때 시작 메뉴 버튼에 포커스를 맞춤
func _ready():
	$PausePanel/VBoxContainer/ResumeButton.grab_focus()

# 계속하기 버튼
func _on_resume_button_pressed():
	# 게임 재개
	get_tree().paused = false
	# 일시 정지 메뉴 숨김
	queue_free()

# 레벨 다시 시작 버튼
func _on_restart_button_pressed():
	queue_free()
	# 게임 재개
	get_tree().paused = false
	# 현재 씬 다시 로드
	get_tree().reload_current_scene()

# 메인 메뉴 버튼
func _on_main_menu_button_pressed():
	queue_free()
	# 게임 재개
	get_tree().paused = false
	# 메인 메뉴로 이동
	get_tree().change_scene_to_file("res://FINAL GAME SCENES/Menu.tscn")
