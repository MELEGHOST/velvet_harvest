extends Node
## Система стелса и ночных событий

@export var stealth_enabled: bool = true
@export var base_detection_range: float = 150.0
@export var light_reduction_factor: float = 0.5

var is_night: bool = false
var active_intruders: Array[Node2D] = []
var player_stealth_level: float = 0.0

signal intruder_spotted(intruder: Node2D)
signal night_started()
signal night_ended()


func _ready() -> void:
	if TimeSystem:
		TimeSystem.time_of_day_changed.connect(_on_time_changed)


func _process(_delta: float) -> void:
	if is_night and stealth_enabled:
		process_intruders()
		update_player_stealth()


func _on_time_changed(is_night_time: bool) -> void:
	if is_night_time != is_night:
		is_night = is_night_time
		if is_night:
			night_started.emit()
			spawn_intruders()
		else:
			night_ended.emit()
			clear_intruders()


func spawn_intruders() -> void:
	var intruder_count = randi_range(1, 3)
	for i in range(intruder_count):
		var intruder = create_intruder()
		if intruder:
			active_intruders.append(intruder)
			add_child(intruder)


func create_intruder() -> Node2D:
	var intruder = CharacterBody2D.new()
	intruder.name = "Intruder_" + str(Time.get_ticks_msec())
	
	var sprite = ColorRect.new()
	sprite.offset_left = -15.0
	sprite.offset_top = -15.0
	sprite.offset_right = 15.0
	sprite.offset_bottom = 15.0
	sprite.color = Color(0.3, 0.1, 0.1, 1)
	intruder.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	collision.shape = shape
	intruder.add_child(collision)
	
	var angle = randf() * TAU
	var distance = randf_range(200.0, 500.0)
	intruder.global_position = Vector2(cos(angle), sin(angle)) * distance
	
	return intruder


func process_intruders() -> void:
	for intruder in active_intruders:
		if not is_instance_valid(intruder):
			continue
		
		var target = find_nearest_target(intruder)
		if target:
			move_intruder_towards(intruder, target)
		
		if detect_intruder(intruder):
			intruder_spotted.emit(intruder)


func find_nearest_target(_intruder: Node2D) -> Node2D:
	return null


func move_intruder_towards(intruder: Node2D, target: Node2D) -> void:
	var direction = (target.global_position - intruder.global_position).normalized()
	intruder.velocity = direction * 60.0
	intruder.move_and_slide()


func detect_intruder(_intruder: Node2D) -> bool:
	return false


func update_player_stealth() -> void:
	var light_sources = get_light_sources()
	var nearest_light = get_nearest_light_distance(light_sources)
	
	player_stealth_level = 1.0
	
	if nearest_light < base_detection_range:
		player_stealth_level = (nearest_light / base_detection_range) * light_reduction_factor
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.velocity.length() > 10.0:
		player_stealth_level *= 0.7


func get_light_sources() -> Array:
	var lights = []
	return lights


func get_nearest_light_distance(lights: Array) -> float:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return 9999.0
	
	var min_distance = 9999.0
	for light in lights:
		var dist = player.global_position.distance_to(light.global_position)
		min_distance = min(min_distance, dist)
	
	return min_distance


func can_hide_in_building(building: Node2D) -> bool:
	return building.has_method("can_interact") and building.can_interact()


func hide_in_building(building: Node2D) -> void:
	if can_hide_in_building(building):
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.visible = false
			player_stealth_level = 1.0


func use_trap(_trap_position: Vector2) -> void:
	pass


func use_light_source(_light_position: Vector2) -> void:
	pass


func clear_intruders() -> void:
	for intruder in active_intruders:
		if is_instance_valid(intruder):
			intruder.queue_free()
	active_intruders.clear()
