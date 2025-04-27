extends CharacterBody2D
@onready var walk_time = $Timer
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var ASP_Walk = $ASP_Walking
@onready var ASP_Jump = $ASP_Jumping
@onready var ASP_Death = $ASP_Death
@onready var ASP_Landed = $ASP_Landed

var on_ice: bool = false
@export var ice_acceleration: float = 200.0    # 얼음 위에서 속도 변화량
@export var ice_friction: float     = 50.0     # 얼음 위에서 감속량
@export var ice_max_speed_multiplier: float = 1.15  # 얼음 위 최대 속도 배율

var was_on_ice = false
var ice_grace_time = 0.2  # 얼음 효과를 유지할 여유시간 (초)
var ice_timer = 0.0  # 현재 남은 여유시간

@export var coyote_time = 0.1
@export var grav_mult = 1
@export var jump_height = 2
@export var jump_animation_speed = 0.5

# 벽 점프 변수
@export var wall_jump_horizontal_power = 200.0  # 벽 점프 시 수평 이동력
@export var wall_jump_time = 0.15  # 벽 점프 후 입력 제한 시간
var is_wall_jumping = false
var wall_jump_timer = 0.0
var wall_direction = 0  # 벽의 방향 (-1: 왼쪽, 1: 오른쪽)
var can_wall_jump = false  # 벽 점프 가능 여부

# 스테미나 변수
@export var max_stamina = 100.0
@export var stamina_recovery_rate = 20.0  # 초당 회복량
@export var sprint_stamina_cost = 20.0    # 초당 소모량
@export var wall_jump_stamina_cost = 25.0 # 벽 점프당 소모량
var current_stamina = 100.0
var is_stamina_exhausted = false
var stamina_recovery_delay = 1.0  # 스테미나 회복 시작 전 딜레이
var stamina_recovery_timer = 0.0
var stamina_bar = null

var was_on_floor = true
var times_landed = 0
@export var RUN_SPEED = 130.0  # 달리기 속도 (기존 SPEED 값)
@export var WALK_SPEED = 70.0   # 걷기 속도 (새로 추가, 더 느린 속도)
@export var JUMP_VELOCITY = -300.0
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#player control over sprite
var can_ctrl : bool = true
#not using is_jumping though?
var is_jumping : bool = false
var coyote_timer : float = 0

func _ready():
	# 스테미나 초기화
	current_stamina = max_stamina
	
	# 기존 스테미나 바 제거 (있다면)
	if has_node("StaminaBar"):
		get_node("StaminaBar").queue_free()
	
	if has_node("StaminaBarLayer"):
		get_node("StaminaBarLayer").queue_free()
	
	if has_node("StaminaBarControl"):
		get_node("StaminaBarControl").queue_free()
	
	# 새 스테미나 바 생성 - Control 노드 사용
	var control = Control.new()
	control.name = "StaminaBarControl"
	add_child(control)
	
	var progress_bar = ProgressBar.new()
	progress_bar.name = "StaminaBar"
	progress_bar.max_value = max_stamina
	progress_bar.value = current_stamina
	
	# 크기를 작게 조정
	progress_bar.custom_minimum_size = Vector2(12, 2)
	progress_bar.position = Vector2(-4.5, -20)  # 플레이어 기준 상단 중앙
	
	# 퍼센트 숫자 숨기기
	progress_bar.show_percentage = false
	
	# 스타일 설정
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.5)  # 배경색 (더 진한 회색)
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 1
	progress_bar.add_theme_stylebox_override("background", style)
	
	var fg_style = StyleBoxFlat.new()
	fg_style.bg_color = Color(0, 1.0, 0, 0.8)  # 전경색 (더 진한 녹색)
	fg_style.corner_radius_top_left = 1
	fg_style.corner_radius_top_right = 1
	fg_style.corner_radius_bottom_left = 1
	fg_style.corner_radius_bottom_right = 1
	progress_bar.add_theme_stylebox_override("fill", fg_style)
	
	control.add_child(progress_bar)
	stamina_bar = progress_bar
	
	# 스테미나가 최대치면 숨김
	if current_stamina >= max_stamina:
		control.visible = false

func _physics_process(delta):
	if not can_ctrl:
		# 사망 시에도 스테미나 관리는 계속 함
		manage_stamina(delta)
		update_stamina_ui()
		return
	
	# 스테미나 관리
	manage_stamina(delta)
	
	# 벽 점프 타이머 업데이트
	if is_wall_jumping:
		wall_jump_timer -= delta
		if wall_jump_timer <= 0:
			is_wall_jumping = false
	
	# 벽 감지 - 벽 점프 가능 여부 확인
	can_wall_jump = false
	wall_direction = 0
	if is_on_wall() and not is_on_floor():
		var normal = get_wall_normal()
		wall_direction = -1 if normal.x > 0 else 1
		can_wall_jump = true
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * grav_mult * delta
		
	#handles landing sfx
	if not was_on_floor and is_on_floor():
		times_landed += 1
		if times_landed >= 2:
			ASP_Landed.play()
		
	was_on_floor = is_on_floor()
	
	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_timer < coyote_time:
			velocity.y = JUMP_VELOCITY
			ASP_Jump.play() #handles jump sfx
		elif can_wall_jump and current_stamina >= wall_jump_stamina_cost:
			# 벽 점프 실행 + 스테미나 소모
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_jump_horizontal_power * -wall_direction  # 벽에서 반대 방향으로 점프
			is_wall_jumping = true
			wall_jump_timer = wall_jump_time
			ASP_Jump.play()
			
			# 스테미나 소모
			current_stamina -= wall_jump_stamina_cost
			stamina_recovery_timer = stamina_recovery_delay
	
	#varible jump height (this is so fucking clean)
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y = jump_height
	
	# Get the input direction and handle the movement/deceleration. (either -1, 0, 1)
	var direction = 0
	if not is_wall_jumping:  # 벽 점프 중이 아닐 때만 입력 허용
		direction = Input.get_axis("move_left", "move_right")
	
	# 달리기 상태 확인 - InputMap 대신 직접 Shift 키 확인 + 스테미나 확인
	var is_sprinting = Input.is_key_pressed(KEY_SHIFT) and current_stamina > 0 and not is_stamina_exhausted
	var current_speed = RUN_SPEED if is_sprinting else WALK_SPEED
	
	# 달리기 중 스테미나 소모
	if is_sprinting and direction != 0:
		current_stamina -= sprint_stamina_cost * delta
		stamina_recovery_timer = stamina_recovery_delay
		
		# 스테미나 완전 소진 시 탈진 상태
		if current_stamina <= 0:
			current_stamina = 0
			is_stamina_exhausted = true
	
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
		
	#play animations and coyote time manager (this is so scuffed)
	if is_on_floor():
		coyote_timer = 0
		animated_sprite_2d.speed_scale = 1.0  # 지상에서는 기본 애니메이션 속도로 복원
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			# 달리기 상태에 따라 애니메이션 속도 조절 (선택 사항)
			animated_sprite_2d.play("run")
			if is_sprinting:
				animated_sprite_2d.speed_scale = 1.2  # 달릴 때 애니메이션 속도 약간 증가
			else:
				animated_sprite_2d.speed_scale = 0.8  # 걸을 때 애니메이션 속도 약간 감소
	else:
		coyote_timer += delta
		if times_landed >= 1:
			animated_sprite_2d.play("jump")
			animated_sprite_2d.speed_scale = jump_animation_speed  # 점프 애니메이션 속도 조절
				
	on_ice = false
	if is_on_floor():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_normal().dot(Vector2.UP) > 0.7:  # 바닥 판정
				if collision.get_collider().is_in_group("ice"):
					on_ice = true
					ice_timer = ice_grace_time
					break
	elif ice_timer > 0:
		ice_timer -= delta
		on_ice = true
	else:
		on_ice = false
			
	# 얼음 위 슬라이딩 로직
	if is_on_floor():
		if on_ice:
			var ice_max_speed = RUN_SPEED * ice_max_speed_multiplier  # 얼음 최대 속도 계산
			var target = direction * ice_max_speed
			if direction != 0:
				velocity.x = move_toward(velocity.x, target, ice_acceleration * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, ice_friction * delta)
		elif was_on_ice:
			velocity.x = move_toward(velocity.x, 0, ice_friction * delta)
			if abs(velocity.x) < 1.0:
				was_on_ice = false
		else:
			if direction:
				velocity.x = direction * current_speed
			else:
				velocity.x = move_toward(velocity.x, 0, current_speed)

	else:
		# 일반 바닥 또는 공중일 때 기존 이동 로직
		if direction:
			velocity.x = direction * current_speed  # 걷기/달리기에 따라 속도 적용
			
			# --- 여기부터 원본 Walk SFX 처리 ---
			if is_on_floor():
				if walk_time.is_stopped():
					print("WALK SFX LOOP CONFIRMED")
					
					if is_sprinting:
						ASP_Walk.pitch_scale = randf_range(1.1, 1.5)
					else:
						ASP_Walk.pitch_scale = randf_range(0.9, 1.1)
						
					ASP_Walk.play()
					
					if is_sprinting:
						walk_time.start(0.2)
				else:
					walk_time.start(0.4)
			# --- 여기까지 원본 Walk SFX 처리 ---
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
	
		
	move_and_slide()
	
	# 스테미나 바 업데이트
	update_stamina_ui()

# 스테미나 관리 함수
func manage_stamina(delta):
	# 스테미나 회복 타이머 업데이트
	if stamina_recovery_timer > 0:
		stamina_recovery_timer -= delta
	
	# 스테미나 회복 (달리기나 벽 점프를 하지 않을 때)
	if stamina_recovery_timer <= 0:
		current_stamina += stamina_recovery_rate * delta
		current_stamina = min(current_stamina, max_stamina)
		
		# 일정 수준 이상 회복되면 탈진 상태 해제
		if current_stamina > max_stamina * 0.3 and is_stamina_exhausted:
			is_stamina_exhausted = false

# 스테미나 바 UI 업데이트
func update_stamina_ui():
	if stamina_bar and has_node("StaminaBarControl"):
		stamina_bar.value = current_stamina
		
		# 스테미나가 최대치일 때 숨김 처리
		var control = get_node("StaminaBarControl")
		if current_stamina >= max_stamina:
			control.visible = false
		else:
			control.visible = true
		
		# 스테미나 상태에 따라 색상 변경
		var fill_style = stamina_bar.get_theme_stylebox("fill", "")
		if fill_style is StyleBoxFlat:
			if current_stamina < max_stamina * 0.2:
				fill_style.bg_color = Color(1, 0, 0, 0.8)  # 빨간색 (낮음) - 더 진하게
			elif current_stamina < max_stamina * 0.5:
				fill_style.bg_color = Color(1, 1, 0, 0.8)  # 노란색 (중간) - 더 진하게
			else:
				fill_style.bg_color = Color(0, 1.0, 0, 0.8)  # 초록색 (높음) - 더 진하게

#handles death animation and removing player ctrl
func handle_danger() -> void:
	print("death animation")
	can_ctrl = false
	animated_sprite_2d.play("death")
	ASP_Death.play()
	
# 키 입력 감지 함수 추가
func _input(event):
	# Esc 키가 눌렸을 때
	if event.is_action_pressed("ui_cancel"):
		# 이미 일시 정지 상태가 아닐 때만 처리
		if not get_tree().paused:
			pause_game()

# 게임 일시 정지 함수
func pause_game():
	# 게임 일시 정지
	get_tree().paused = true
	
	# 일시 정지 메뉴 씬 로드
	var pause_menu_scene = load("res://assets/scenes/UI/pause_menu.tscn")
	var pause_menu = pause_menu_scene.instantiate()
	
	# 현재 씬에 일시 정지 메뉴 추가
	get_tree().root.add_child(pause_menu)
