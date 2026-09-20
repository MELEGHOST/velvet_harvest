extends Node
## Система скрещивания семян

signal hybrid_created(hybrid_data: CropData)
signal breeding_failed(reason: String)

# Лимиты
@export var max_breeding_slots: int = 4
var active_breeding: Array[Dictionary] = []

# Шансы
@export var base_success_chance: float = 0.7  # 70% базовый шанс успеха
@export var mutation_chance: float = 0.1  # 10% шанс мутации

func _process(delta: float) -> void:
process_breeding(delta)

func can_breed() -> bool:
return active_breeding.size() < max_breeding_slots

func start_breeding(parent1: CropData, parent2: CropData) -> bool:
if not can_breed():
breeding_failed.emit("Слишком много активных скрещиваний")
return false

# Проверка совместимости
if not are_compatible(parent1, parent2):
breeding_failed.emit("Растения несовместимы")
return false

var breeding_slot = {
"parent1": parent1,
"parent2": parent2,
"progress": 0.0,
"complete": false
}

active_breeding.append(breeding_slot)
return true

func are_compatible(parent1: CropData, parent2: CropData) -> bool:
# Базовая проверка - растения должны быть одного типа или соседних
if parent1.crop_type == parent2.crop_type:
return true

# Разные типы могут скрещиваться с меньшим шансом
var compatible_types = {
"vegetable": ["flower"],
"berry": ["flower"],
"flower": ["vegetable", "berry"]
}

return parent2.crop_type in compatible_types.get(parent1.crop_type, [])

func process_breeding(delta: float) -> void:
for i in range(active_breeding.size() - 1, -1, -1):
var slot = active_breeding[i]

if slot.complete:
continue

# Прогресс скрещивания (5 игровых дней)
slot.progress += delta / (5.0 * 24.0)

if slot.progress >= 1.0:
slot.complete = true
var result = complete_breeding(slot)

if result:
hybrid_created.emit(result)

active_breeding.remove_at(i)

func complete_breeding(slot: Dictionary) -> CropData:
var parent1 = slot.parent1 as CropData
var parent2 = slot.parent2 as CropData

# Проверка успеха
if randf() > calculate_success_chance(parent1, parent2):
breeding_failed.emit("Скрещивание не удалось")
return null

# Создание гибрида
var hybrid = create_hybrid_data(parent1, parent2)

return hybrid

func calculate_success_chance(parent1: CropData, parent2: CropData) -> float:
var chance = base_success_chance

# Бонус за одинаковый тип
if parent1.crop_type == parent2.crop_type:
chance += 0.15

# Штраф за большую разницу в редкости
var rarity_diff = abs(parent1.rarity - parent2.rarity)
chance -= rarity_diff * 0.05

return clamp(chance, 0.1, 0.95)

func create_hybrid_data(parent1: CropData, parent2: CropData) -> CropData:
var hybrid = CropData.new()

# Генерация ID гибрида
hybrid.crop_id = "hybrid_" + parent1.crop_id + "_" + parent2.crop_id + "_" + str(Time.get_ticks_msec())
hybrid.crop_name = parent1.crop_name + "-" + parent2.crop_name + " Гибрид"

# Тип наследуется от одного из родителей
if randf() < 0.5:
hybrid.crop_type = parent1.crop_type
else:
hybrid.crop_type = parent2.crop_type

# Смешивание характеристик
hybrid.growth_days = int((parent1.growth_days + parent2.growth_days) / 2.0)
hybrid.yield_amount = int(ceil((parent1.yield_amount + parent2.yield_amount) / 2.0))

# Редкость может увеличиться
var avg_rarity = (parent1.rarity + parent2.rarity) / 2.0
if randf() < mutation_chance:
hybrid.rarity = min(10, int(avg_rarity) + randi_range(1, 3))
else:
hybrid.rarity = int(avg_rarity)

# Комбинирование особых эффектов
var combined_effects = parent1.special_effects.duplicate()
for effect in parent2.special_effects:
if not effect in combined_effects:
combined_effects.append(effect)
hybrid.special_effects = combined_effects

# Цена
hybrid.base_price = int((parent1.base_price + parent2.base_price) * 1.5)
hybrid.seed_cost = int((parent1.seed_cost + parent2.seed_cost) * 1.3)

# Требования к температуре (средние)
hybrid.min_temperature = max(parent1.min_temperature, parent2.min_temperature)
hybrid.max_temperature = min(parent1.max_temperature, parent2.max_temperature)
hybrid.water_requirement = (parent1.water_requirement + parent2.water_requirement) / 2.0

return hybrid

func cancel_breeding(index: int) -> void:
if index >= 0 and index < active_breeding.size():
active_breeding.remove_at(index)

func get_active_breeding_count() -> int:
return active_breeding.size()

func get_breeding_progress(index: int) -> float:
if index >= 0 and index < active_breeding.size():
return active_breeding[index].progress
return 0.0
