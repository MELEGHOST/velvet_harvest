class_name CropData
extends Resource
## Данные для культуры

@export var crop_id: String
@export var crop_name: String
@export var crop_type: String  # "vegetable", "berry", "flower"

# Базовые свойства
@export var growth_days: int = 3  # Дней до созревания
@export var yield_amount: int = 1  # Количество урожая
@export var rarity: int = 1  # 1-10, где 10 - самая редкая

# Особые эффекты
@export var special_effects: Array[String] = []  # "aroma", "color_boost", "taste_enhancement"

# Визуализация
@export var sprite_texture: Texture2D
@export var mature_sprite: Texture2D

# Экономика
@export var base_price: int = 10  # Базовая цена в мелонах
@export var seed_cost: int = 5  # Стоимость семени

# Требования
@export var min_temperature: float = 10.0
@export var max_temperature: float = 35.0
@export var water_requirement: float = 0.5  # 0.0-1.0

func get_sell_price(modifier: float = 1.0) -> int:
	return int(base_price * modifier * (rarity * 0.1))

func can_grow_in_season(season: String) -> bool:
	match crop_type:
		"vegetable":
			return season in ["spring", "summer"]
		"berry":
			return season in ["summer", "autumn"]
		"flower":
			return season in ["spring", "summer"]
	return true
