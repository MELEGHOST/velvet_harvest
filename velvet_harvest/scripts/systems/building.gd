class_name Building
extends StaticBody2D
## Здание на карте

@export var building_data: BuildingData
@export var construction_stage: int = 0  # 0-3

var is_complete: bool = false
var health: float = 100.0
var max_health: float = 100.0

signal construction_completed()
signal damaged(new_health: float)
signal destroyed()

func _ready() -> void:
	update_visuals()
	if construction_stage >= 3:
		is_complete = true

func update_visuals() -> void:
	# Здесь будет логика обновления спрайтов в зависимости от стадии строительства
	# Для сейчас просто заглушка
	match construction_stage:
		0: # Foundation
			pass
		1: # Walls
			pass
		2: # Roof
			pass
		3: # Finished
			is_complete = true
			construction_completed.emit()

func advance_construction() -> void:
	if construction_stage < 3:
		construction_stage += 1
		update_visuals()
		
		if construction_stage == 3:
			GameState.add_building(building_data.building_id)
			construction_completed.emit()
			
			# Открытие рецептов крафта
			for recipe in building_data.crafting_recipes:
				if not recipe in GameState.unlocked_recipes:
					GameState.unlocked_recipes.append(recipe)

func take_damage(amount: float) -> void:
	health -= amount
	damaged.emit(health)
	
	if health <= 0:
		destroyed.emit()
		queue_free()

func repair(amount: float) -> void:
	health = min(max_health, health + amount)
	damaged.emit(health)

func get_stage_name() -> String:
	if construction_stage < building_data.stages.size():
		return building_data.stages[construction_stage]
	return "unknown"

func can_interact() -> bool:
	return is_complete

func interact() -> void:
	if not can_interact():
		return
	
	# Логика взаимодействия со зданием
	if building_data.enables_crafting:
		# Открыть интерфейс крафта
		pass
	elif building_data.storage_slots > 0:
		# Открыть интерфейс хранения
		pass
