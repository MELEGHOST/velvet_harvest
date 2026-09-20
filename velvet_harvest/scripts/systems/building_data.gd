class_name BuildingData
extends Resource
## Данные для здания

@export var building_id: String
@export var building_name: String
@export var description: String

# Требования для постройки
@export var required_buildings: Array[String] = []  # Какие здания должны быть построены сначала
@export var required_tools: Array[String] = []  # Необходимые инструменты

# Стоимость постройки
@export var wood_cost: int = 0
@export var stone_cost: int = 0
@export var metal_cost: int = 0
@export var melon_cost: int = 0  # Деньги

# Размеры
@export var size: Vector2 = Vector2(100, 100)  # Размер в пикселях
@export var collision_size: Vector2 = Vector2(100, 100)  # Размер коллизии

# Этапы строительства
enum ConstructionStage { FOUNDATION, WALLS, ROOF, FINISHED }
var stages: Array[String] = ["foundation", "walls", "roof", "finished"]

# Визуализация
@export var foundation_sprite: Texture2D
@export var walls_sprite: Texture2D
@export var roof_sprite: Texture2D
@export var finished_sprite: Texture2D

# Функциональность
@export var provides_shelter: bool = false
@export var enables_crafting: bool = false
@export var crafting_recipes: Array[String] = []  # Открытые рецепты
@export var storage_slots: int = 0  # Слоты хранения
@export var enables_farming: bool = false  # Теплица
@export var enables_breeding: bool = false  # Лаборатория

# Время постройки (в игровых часах)
@export var construction_time: float = 2.0

func can_build() -> bool:
	# Проверка наличия требуемых зданий
	for required in required_buildings:
		if not GameState.has_building(required):
			return false
	
	# Проверка ресурсов
	if GameState.melons < melon_cost:
		return false
	if GameState.inventory.get("wood", 0) < wood_cost:
		return false
	if GameState.inventory.get("stone", 0) < stone_cost:
		return false
	if GameState.inventory.get("metal", 0) < metal_cost:
		return false
	
	return true

func get_construction_cost() -> Dictionary:
	return {
		"wood": wood_cost,
		"stone": stone_cost,
		"metal": metal_cost,
		"melons": melon_cost
	}

func pay_cost() -> bool:
	if not can_build():
		return false
	
	GameState.spend_melons(melon_cost)
	if wood_cost > 0:
		GameState.remove_from_inventory("wood", wood_cost)
	if stone_cost > 0:
		GameState.remove_from_inventory("stone", stone_cost)
	if metal_cost > 0:
		GameState.remove_from_inventory("metal", metal_cost)
	
	return true
