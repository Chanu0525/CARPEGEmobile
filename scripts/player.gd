extends CharacterBody2D
class_name Player
@onready var walk_time = $Timer
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var ASP_Walk = $ASP_Walking
@onready var ASP_Jump = $ASP_Jumping
@onready var ASP_Death = $ASP_Death
@onready var ASP_Landed = $ASP_Landed

var on_ice: bool = false
@export var ice_acceleration: float = 200.0
@export var ice_friction: float = 50.0
@export var ice_max_speed_multiplier: float = 1.15

var was_on_ice = false
var ice_grace_time = 0.2
var ice_timer = 0.0
var ice_exit_timer = 0.0
var ice_exit_max_time = 0.1

var left_tap_time := 0.0
var left_tap_count := 0
var right_tap_time := 0.0
var right_tap_count := 0
var tap_threshold := 0.3
var is_touch_sprinting := false

@export var coyote_time = 0.1
@export var grav_mult = 1
@export var jump_height = 2
@export var jump_animation_speed = 0.5

@export var wall_jump_horizontal_power = 200.0
@export var wall_jump_time = 0.15
var is_wall_jumping = false
var wall_jump_timer = 0.0
var wall_direction = 0
var can_wall_jump = false

@export var max_stamina = 100.0
@export var stamina_recovery_rate = 20.0
@export var sprint_stamina_cost = 20.0
@export var wall_jump_stamina_cost = 25.0
var current_stamina = 100.0
var is_stamina_exhausted = false
var stamina_recovery_delay = 1.0
var stamina_recovery_timer = 0.0
var stamina_bar = null

var was_on_floor = true
var times_landed = 0
@export var RUN_SPEED = 130.0
@export var WALK_SPEED = 70.0
@export var JUMP_VELOCITY = -300.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_ctrl : bool = true
var is_jumping : bool = false
var coyote_timer : float = 0

func _on_left_pressed():
	var now = Time.get_ticks_msec() / 1000.0
	if now - left_tap_time < tap_threshold:
		left_tap_count += 1
	else:
		left_tap_count = 1
	left_tap_time = now
	if left_tap_count >= 2:
		is_touch_sprinting = true

func _on_right_pressed():
	var now = Time.get_ticks_msec() / 1000.0
	if now - right_tap_time < tap_threshold:
		right_tap_count += 1
	else:
		right_tap_count = 1
	right_tap_time = now
	if right_tap_count >= 2:
		is_touch_sprinting = true

func find_node_recursive(node: Node, target_name: String) -> Node:
	for child in node.get_children():
		if child.name == target_name:
			return child
		var result = find_node_recursive(child, target_name)
		if result != null:
			return result
	return null

func _ready():
	current_stamina = max_stamina
	var left_button = find_node_recursive(get_tree().root, "LEFT")
	var right_button = find_node_recursive(get_tree().root, "RIGHT")
	if left_button:
		left_button.pressed.connect(_on_left_pressed)
	if right_button:
		right_button.pressed.connect(_on_right_pressed)

	if has_node("StaminaBar"): get_node("StaminaBar").queue_free()
	if has_node("StaminaBarLayer"): get_node("StaminaBarLayer").queue_free()
	if has_node("StaminaBarControl"): get_node("StaminaBarControl").queue_free()

	var control = Control.new()
	control.name = "StaminaBarControl"
	add_child(control)

	var progress_bar = ProgressBar.new()
	progress_bar.name = "StaminaBar"
	progress_bar.max_value = max_stamina
	progress_bar.value = current_stamina
	progress_bar.custom_minimum_size = Vector2(12, 2)
	progress_bar.position = Vector2(-4.5, -20)
	progress_bar.show_percentage = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 1
	progress_bar.add_theme_stylebox_override("background", style)

	var fg_style = StyleBoxFlat.new()
	fg_style.bg_color = Color(0, 1.0, 0, 0.8)
	fg_style.corner_radius_top_left = 1
	fg_style.corner_radius_top_right = 1
	fg_style.corner_radius_bottom_left = 1
	fg_style.corner_radius_bottom_right = 1
	progress_bar.add_theme_stylebox_override("fill", fg_style)

	control.add_child(progress_bar)
	stamina_bar = progress_bar
	control.visible = current_stamina < max_stamina

func _physics_process(delta):
	if not can_ctrl:
		manage_stamina(delta)
		update_stamina_ui()
		return

	manage_stamina(delta)

	if is_wall_jumping:
		wall_jump_timer -= delta
		if wall_jump_timer <= 0:
			is_wall_jumping = false

	can_wall_jump = false
	wall_direction = 0
	if is_on_wall() and not is_on_floor():
		var normal = get_wall_normal()
		wall_direction = -1 if normal.x > 0 else 1
		can_wall_jump = true

	if not is_on_floor():
		velocity.y += gravity * grav_mult * delta

	if not was_on_floor and is_on_floor():
		times_landed += 1
		if times_landed >= 2:
			ASP_Landed.play()
	was_on_floor = is_on_floor()

	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_timer < coyote_time:
			velocity.y = JUMP_VELOCITY
			ASP_Jump.play()
		elif can_wall_jump and current_stamina >= wall_jump_stamina_cost:
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_jump_horizontal_power * -wall_direction
			is_wall_jumping = true
			wall_jump_timer = wall_jump_time
			ASP_Jump.play()
			current_stamina -= wall_jump_stamina_cost
			stamina_recovery_timer = stamina_recovery_delay

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y = jump_height

	var direction = 0
	if not is_wall_jumping:
		direction = Input.get_axis("move_left", "move_right")

	if direction == 0:
		is_touch_sprinting = false

	var is_sprinting = (Input.is_action_pressed("sprint") or is_touch_sprinting) and current_stamina > 0 and not is_stamina_exhausted
	var current_speed = RUN_SPEED if is_sprinting else WALK_SPEED

	if is_sprinting and direction != 0:
		current_stamina -= sprint_stamina_cost * delta
		stamina_recovery_timer = stamina_recovery_delay
		if current_stamina <= 0:
			current_stamina = 0
			is_stamina_exhausted = true

	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true

	if is_on_floor():
		coyote_timer = 0
		animated_sprite_2d.speed_scale = 1.0
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
			animated_sprite_2d.speed_scale = 1.2 if is_sprinting else 0.8
		if not on_ice:
			was_on_ice = false
	else:
		coyote_timer += delta
		if times_landed >= 1:
			animated_sprite_2d.play("jump")
			animated_sprite_2d.speed_scale = jump_animation_speed
			
	# 얼음 타일 체크
	on_ice = false
	if is_on_floor():
		var space_state = get_world_2d().direct_space_state
		var check_pos = global_position + Vector2(0, 2)
		var query = PhysicsPointQueryParameters2D.new()
		query.position = check_pos
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.collision_mask = 1
		var result = space_state.intersect_point(query)
		for item in result:
			if item.collider.is_in_group("ice"):
				on_ice = true
				ice_timer = ice_grace_time
				ice_exit_timer = ice_exit_max_time
				break
	elif ice_timer > 0:
		ice_timer -= delta
		on_ice = true
	else:
		on_ice = false

	# 얼음에서 나왔지만 남은 관성 처리 시간
	if not on_ice and ice_exit_timer > 0:
		ice_exit_timer -= delta
		on_ice = true

	# 물리 적용 (수정된 얼음 관성 처리)
	if is_on_floor():
		if on_ice:
			was_on_ice = true
			var ice_max_speed = RUN_SPEED * ice_max_speed_multiplier
			var target = direction * ice_max_speed
			velocity.x = move_toward(velocity.x, target, ice_acceleration * delta if direction != 0 else ice_friction * delta)
		elif was_on_ice and ice_timer > 0.0:
			velocity.x = move_toward(velocity.x, 0, ice_friction * delta)
			if abs(velocity.x) < 1.0:
				was_on_ice = false
				ice_timer = 0.0
		else:
			velocity.x = direction * current_speed if direction else move_toward(velocity.x, 0, current_speed)
	else:
		if was_on_ice and ice_timer > 0.0:
			velocity.x = move_toward(velocity.x, 0, ice_friction * delta)
			if abs(velocity.x) < 1.0:
				was_on_ice = false
				ice_timer = 0.0
		elif direction:
			velocity.x = direction * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)

	move_and_slide()
	update_stamina_ui()

func manage_stamina(delta):
	if stamina_recovery_timer > 0:
		stamina_recovery_timer -= delta
	if stamina_recovery_timer <= 0:
		current_stamina += stamina_recovery_rate * delta
		current_stamina = min(current_stamina, max_stamina)
		if current_stamina > max_stamina * 0.3 and is_stamina_exhausted:
			is_stamina_exhausted = false

func update_stamina_ui():
	if stamina_bar and has_node("StaminaBarControl"):
		stamina_bar.value = current_stamina
		var control = get_node("StaminaBarControl")
		control.visible = current_stamina < max_stamina
		var fill_style = stamina_bar.get_theme_stylebox("fill", "")
		if fill_style is StyleBoxFlat:
			if current_stamina < max_stamina * 0.2:
				fill_style.bg_color = Color(1, 0, 0, 0.8)
			elif current_stamina < max_stamina * 0.5:
				fill_style.bg_color = Color(1, 1, 0, 0.8)
			else:
				fill_style.bg_color = Color(0, 1.0, 0, 0.8)

func handle_danger() -> void:
	print("death animation")
	can_ctrl = false
	animated_sprite_2d.play("death")
	ASP_Death.play()

func _input(event):
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		pause_game()

func pause_game():
	get_tree().paused = true
	var pause_menu_scene = load("res://assets/scenes/UI/pause_menu.tscn")
	var pause_menu = pause_menu_scene.instantiate()
	get_tree().root.add_child(pause_menu)
