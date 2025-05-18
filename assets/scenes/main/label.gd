extends Label

func _ready():
	randomize()  # 무작위 시드 초기화
	var random_number = randi_range(10000000, 99999999)  # 8자리 숫자
	text = str(random_number)
