class_name CropPlot
extends Node2D
## Грядка с растением

@export var crop_data: CropData
@export var plot_size: Vector2 = Vector2(64, 64)

# Состояние роста
var growth_progress: float = 0.0  # 0.0 - 1.0
var water_level: float = 0.0  # 0.0 - 1.0
var fertilizer_level: float = 0.0  # 0.0 - 1.0
var health: float = 1.0  # 0.0 - 1.0
var is_planted: bool = false
var is_mature: bool = false

# Периоды роста (в игровых днях)
var growth_stages: Array[float] = [0.25, 0.5, 0.75, 1.0]
var current_stage: int = 0

# Вредители и болезни
var has_pests: bool = false
var has_disease: bool = false

signal growth_stage_changed(stage: int)
signal maturity_reached()
signal plant_died()
signal needs_water()
signal pests_detected()

func _process(_delta: float) -> void:
    if not is_planted or is_mature:
        return
    
    # Проверка условий роста
    if not can_grow():
        return
    
    # Рост растения
    grow()
    
    # Потребление воды
    consume_water()
    
    # Проверка на вредителей
    check_pests()

func plant(seed_data: CropData) -> bool:
    if is_planted:
        return false
    
    crop_data = seed_data
    is_planted = true
    growth_progress = 0.0
    current_stage = 0
    water_level = 0.3  # Начальный уровень воды
    health = 1.0
    
    return true

func grow() -> void:
    if not crop_data:
        return
    
    # Модификаторы роста
    var growth_rate = 1.0 / (crop_data.growth_days * 24.0)  # Прогресс в час
    
    # Бонус от удобрений
    if fertilizer_level > 0:
        growth_rate *= 1.0 + (fertilizer_level * 0.5)
    
    # Штраф от недостатка воды
    if water_level < crop_data.water_requirement:
        growth_rate *= 0.5
        needs_water.emit()
    
    # Штраф от вредителей
    if has_pests:
        growth_rate *= 0.7
        health -= 0.01
    
    # Применение роста
    growth_progress += growth_rate
    
    # Проверка стадии роста
    var target_stage = 0
    for i in range(growth_stages.size()):
        if growth_progress >= growth_stages[i]:
            target_stage = i + 1
    
    if target_stage > current_stage:
        current_stage = target_stage
        growth_stage_changed.emit(current_stage)
    
    # Проверка зрелости
    if growth_progress >= 1.0 and not is_mature:
        is_mature = true
        maturity_reached.emit()

func water(amount: float) -> void:
    water_level = min(1.0, water_level + amount)

func apply_fertilizer(amount: float) -> void:
    fertilizer_level = min(1.0, fertilizer_level + amount)

func remove_pests() -> void:
    has_pests = false

func consume_water() -> void:
    # Испарение воды
    var evaporation_rate = 0.01
    if TimeSystem.current_weather == "sunny":
        evaporation_rate *= 1.5
    elif TimeSystem.current_weather == "rainy":
        water_level = min(1.0, water_level + 0.1)
        return
    
    water_level = max(0.0, water_level - evaporation_rate)

func can_grow() -> bool:
    if not crop_data:
        return false
    
    var temp = TimeSystem.temperature
    if temp < crop_data.min_temperature or temp > crop_data.max_temperature:
        return false
    
    if health <= 0:
        return false
    
    return true

func check_pests() -> void:
    # Шанс появления вредителей
    var pest_chance = 0.001  # 0.1% каждый кадр
    if TimeSystem.current_weather == "rainy":
        pest_chance *= 2.0
    
    if randf() < pest_chance and not has_pests:
        has_pests = true
        pests_detected.emit()

func harvest() -> Dictionary:
    if not is_mature:
        return {}
    
    var result = {
        "crop_id": crop_data.crop_id,
        "amount": crop_data.yield_amount,
        "quality": calculate_quality(),
        "special_effects": crop_data.special_effects.duplicate()
    }
    
    # Сброс грядки
    reset_plot()
    
    return result

func calculate_quality() -> float:
    var quality = 1.0
    
    # Бонус от правильного полива
    if water_level >= crop_data.water_requirement:
        quality += 0.2
    
    # Бонус от удобрений
    quality += fertilizer_level * 0.3
    
    # Штраф от вредителей
    if has_pests:
        quality *= 0.7
    
    # Штраф от болезней
    if has_disease:
        quality *= 0.5
    
    return clamp(quality, 0.1, 2.0)

func reset_plot() -> void:
    is_planted = false
    is_mature = false
    growth_progress = 0.0
    current_stage = 0
    water_level = 0.0
    fertilizer_level = 0.0
    has_pests = false
    has_disease = false
    crop_data = null
