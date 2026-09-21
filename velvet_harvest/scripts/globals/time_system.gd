extends Node
## Система времени и погоды

@export var day_duration_seconds: float = 120.0  # Длительность дня в секундах реального времени
@export var start_hour: float = 8.0  # Начало дня (8 утра)

var is_day: bool = true
var current_weather: String = "sunny"
var temperature: float = 20.0

# Типы погоды
enum WeatherType { SUNNY, CLOUDY, RAINY, STORMY, SNOWY }

signal weather_changed(new_weather: String)
signal time_of_day_changed(is_night: bool)
signal season_changed(new_season: String)

var seasons: Array[String] = ["spring", "summer", "autumn", "winter"]
var current_season_index: int = 0
var days_in_season: int = 7  # Для демо-версии, можно увеличить до 21

func _ready() -> void:
    GameState.current_time = start_hour
    update_time_of_day()

func _process(delta: float) -> void:
    # Продвижение времени
    var hours_per_second: float = 24.0 / day_duration_seconds
    GameState.advance_time(hours_per_second * delta)
    
    update_time_of_day()
    check_season_progress()

func update_time_of_day() -> void:
    var was_day = is_day
    is_day = GameState.current_time >= 6.0 and GameState.current_time < 20.0
    
    if is_day != was_day:
        time_of_day_changed.emit(is_day)

func check_season_progress() -> void:
    if GameState.current_day % days_in_season == 0 and GameState.current_time < 0.1:
        current_season_index = (current_season_index + 1) % seasons.size()
        season_changed.emit(seasons[current_season_index])
        generate_weather_for_season()

func generate_weather_for_season() -> void:
    var season = seasons[current_season_index]
    match season:
        "spring":
            set_weather(["sunny", "cloudy", "rainy"])
        "summer":
            set_weather(["sunny", "sunny", "cloudy", "stormy"])
        "autumn":
            set_weather(["sunny", "cloudy", "rainy", "cloudy"])
        "winter":
            set_weather(["sunny", "cloudy", "snowy", "snowy"])

func set_weather(options: Array[String]) -> void:
    var new_weather = options[randi() % options.size()]
    if new_weather != current_weather:
        current_weather = new_weather
        weather_changed.emit(current_weather)

func get_current_season() -> String:
    return seasons[current_season_index]

func is_night() -> bool:
    return not is_day

func can_farm() -> bool:
    # Нельзя фермерствовать ночью или во время бури
    return is_day and current_weather != "stormy"
