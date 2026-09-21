class_name PlayerCharacter
extends CharacterBody2D
## Игрок - молодой парень

@export var speed: float = 200.0
@export var sprint_multiplier: float = 1.5

var is_sprinting: bool = false
var is_building_mode: bool = false
var current_tool: String = "axe_basic"
var carrying_item: String = ""

signal tool_changed(new_tool: String)
signal item_picked_up(item_id: String)
signal building_mode_toggled(is_active: bool)

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	setup_character_appearance()

func setup_character_appearance() -> void:
	# Настройка спрайта для молодого парня (программный пиксель-арт)
	if sprite:
		var texture_size = Vector2i(64, 96)
		var image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
		
		# Цвета для персонажа
		var skin_color = Color(0.95, 0.75, 0.65)
		var hair_color = Color(0.4, 0.25, 0.15)
		var shirt_color = Color(0.3, 0.5, 0.8)
		var pants_color = Color(0.3, 0.3, 0.35)
		var boot_color = Color(0.25, 0.15, 0.1)
		
		# Рисуем персонажа
		for y in range(texture_size.y):
			for x in range(texture_size.x):
				var center_x = texture_size.x / 2.0
				
				# Голова
				if y < 24 and abs(x - center_x) < 12:
					image.set_pixel(x, y, skin_color)
					if y < 10 or (y < 14 and abs(x - center_x) > 8):
						image.set_pixel(x, y, hair_color)
				# Тело
				elif y >= 24 and y < 50 and abs(x - center_x) < 14:
					image.set_pixel(x, y, shirt_color)
				# Ноги
				elif y >= 50 and y < 75:
					if abs(x - center_x) < 6 or (abs(x - center_x) < 10 and y < 55):
						image.set_pixel(x, y, pants_color)
				# Ботинки
				elif y >= 75 and y < texture_size.y:
					if abs(x - center_x) < 6:
						image.set_pixel(x, y, boot_color)
		
		sprite.texture = ImageTexture.create_from_image(image)
		sprite.scale = Vector2(2, 2)

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	is_sprinting = Input.is_key_pressed(KEY_SHIFT)
	var current_speed = speed * (sprint_multiplier if is_sprinting else 1.0)
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		if animation_player and not animation_player.is_playing():
			animation_player.play("walk")
		if sprite:
			sprite.flip_h = input_vector.x < 0
	else:
		if animation_player:
			animation_player.stop()
			animation_player.play("idle")
	
	velocity = input_vector * current_speed
	move_and_slide()
	
	if Input.is_action_just_pressed("interact"):
		interact()
	
	if Input.is_action_just_pressed("build_mode"):
		toggle_build_mode()

func interact() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2.RIGHT * 64.0,
		["world", "buildings", "crops"]
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider.has_method("interact"):
			collider.interact()

func toggle_build_mode() -> void:
	is_building_mode = not is_building_mode
	building_mode_toggled.emit(is_building_mode)

func pick_up_item(item_id: String) -> void:
	carrying_item = item_id
	item_picked_up.emit(item_id)

func drop_item() -> void:
	carrying_item = ""

func use_tool(target: Node2D) -> void:
	match current_tool:
		"axe_basic":
			if target.is_in_group("trees"):
				chop_tree(target)
		"pickaxe_basic":
			if target.is_in_group("rocks"):
				mine_rock(target)
		"hoe_basic":
			if target.is_in_group("soil"):
				till_soil(target)
		"watering_can":
			if target.is_in_group("crops"):
				water_crop(target)

func chop_tree(tree: Node2D) -> void:
	if tree.has_method("take_damage"):
		tree.take_damage(25.0)

func mine_rock(rock: Node2D) -> void:
	if rock.has_method("take_damage"):
		rock.take_damage(15.0)

func till_soil(soil: Node2D) -> void:
	if soil.has_method("till"):
		soil.till()

func water_crop(crop: CropPlot) -> void:
	crop.water(0.3)

func change_tool(new_tool: String) -> void:
	current_tool = new_tool
	tool_changed.emit(new_tool)

func get_inventory() -> Dictionary:
	return GameState.inventory

func add_to_inventory(item_id: String, amount: int = 1) -> void:
	GameState.add_to_inventory(item_id, amount)
	item_picked_up.emit(item_id)
