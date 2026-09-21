extends Node2D
class_name CropPlot

@export var crop_type: String = "carrot"
@export var growth_stage: int = 0
@export var water_level: float = 0.0
@export var health: float = 100.0
@export var max_growth_stages: int = 4

var is_planted: bool = false
var is_watered: bool = false
var has_pests: bool = false

@onready var plant_sprite: Sprite2D = $Plant
@onready var water_indicator: Sprite2D = $WateredIndicator

signal growth_changed(stage)
signal needs_water
signal pest_detected

func _ready():
    update_visuals()

func plant_seed(seed_type: String):
    if is_planted:
        return false
    crop_type = seed_type
    is_planted = true
    growth_stage = 0
    water_level = 50.0
    health = 100.0
    update_visuals()
    return true

func water():
    if not is_planted:
        return false
    water_level = 100.0
    is_watered = true
    update_visuals()
    return true

func apply_fertilizer(amount: float):
    if not is_planted:
        return false
    health = min(100.0, health + amount)
    return true

func remove_pests():
    has_pests = false
    update_visuals()

func grow(delta: float):
    if not is_planted or health <= 0:
        return
    
    if water_level > 0:
        var growth_rate = 1.0
        if has_pests:
            growth_rate = 0.3
        water_level -= delta * 2.0
        if water_level <= 0:
            water_level = 0
            is_watered = false
            emit_signal("needs_water")
        
        growth_stage += int(growth_rate * delta)
        if growth_stage >= max_growth_stages:
            growth_stage = max_growth_stages
        emit_signal("growth_changed", growth_stage)
        update_visuals()

func update_visuals():
    if plant_sprite:
        plant_sprite.visible = is_planted
    if water_indicator:
        water_indicator.visible = is_watered and is_planted

func harvest() -> Dictionary:
    if not is_planted or growth_stage < max_growth_stages - 1:
        return {}
    
    var yield_data = {
        "type": crop_type,
        "quantity": randi_range(1, 3),
        "quality": "normal" if health > 70 else "poor"
    }
    
    is_planted = false
    growth_stage = 0
    water_level = 0
    has_pests = false
    update_visuals()
    
    return yield_data

func _process(delta):
    if is_planted:
        grow(delta)
        if randf() < 0.001 and not has_pests:
            has_pests = true
            emit_signal("pest_detected")
