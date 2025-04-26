extends Area2D

@export var wind_direction := Vector2.LEFT
@export var wind_strength := 50.0

func _ready():
	
	# 신호 연결 (Godot 4.x 방식)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node):
	if body.is_in_group("Player"):
		if not body.active_wind_areas.has(self):
			body.active_wind_areas.append(self)
			body.is_in_wind_zone = true

func _on_body_exited(body: Node):
	if body.is_in_group("Player"):
		body.active_wind_areas.erase(self)
		if body.active_wind_areas.is_empty():
			body.is_in_wind_zone = false
