extends Node
## Глобальное состояние игры - синглтон

# Деньги (мелоны)
var melons: int = 50

# Текущий день
var current_day: int = 1

# Время (0-24 часа)
var current_time: float = 8.0

# Отношения с NPC
var relationships: Dictionary = {
	"vasily": 0,
}

# Открытые рецепты крафта
var unlocked_recipes: Array[String] = ["basic_shelter"]

# Построенные здания
var built_buildings: Array[String] = []

# Инвентарь игрока
var inventory: Dictionary = {
	"wood": 0,
	"stone": 0,
	"metal": 0,
	"seeds": {},
	"crops": {},
	"tools": ["axe_basic"],
}

# Сигналы для обновления UI
signal melons_changed(new_amount: int)
signal day_changed(new_day: int)
signal time_changed(new_time: float)
signal relationship_changed(npc_id: String, new_value: int)
signal building_built(building_id: String)

func add_melons(amount: int) -> void:
	melons += amount
	melons_changed.emit(melons)

func spend_melons(amount: int) -> bool:
	if melons >= amount:
		melons -= amount
		melons_changed.emit(melons)
		return true
	return false

func advance_time(hours: float) -> void:
	current_time += hours
	if current_time >= 24.0:
		current_time -= 24.0
		advance_day()
	time_changed.emit(current_time)

func advance_day() -> void:
	current_day += 1
	day_changed.emit(current_day)

func set_relationship(npc_id: String, value: int) -> void:
	relationships[npc_id] = clamp(value, 0, 100)
	relationship_changed.emit(npc_id, relationships[npc_id])

func change_relationship(npc_id: String, delta: int) -> void:
	if npc_id in relationships:
		set_relationship(npc_id, relationships[npc_id] + delta)
	else:
		set_relationship(npc_id, delta)

func has_building(building_id: String) -> bool:
	return building_id in built_buildings

func add_building(building_id: String) -> void:
	if not has_building(building_id):
		built_buildings.append(building_id)
		building_built.emit(building_id)

func add_to_inventory(item_id: String, amount: int = 1) -> void:
	if item_id in inventory:
		inventory[item_id] += amount
	else:
		inventory[item_id] = amount

func remove_from_inventory(item_id: String, amount: int = 1) -> bool:
	if item_id in inventory and inventory[item_id] >= amount:
		inventory[item_id] -= amount
		if inventory[item_id] <= 0:
			inventory.erase(item_id)
		return true
	return false

func has_item(item_id: String, amount: int = 1) -> bool:
	return item_id in inventory and inventory[item_id] >= amount
