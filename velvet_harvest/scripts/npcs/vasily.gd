extends NPCCharacter
## Охотник Василий - первый ключевой NPC

@export var player_home_position: Vector2

var has_met_player: bool = false
var gives_lifts: bool = false
var family_introduced: bool = false

# Семья Василия
var wife_data: Dictionary = {"name": "Мария", "relationship": 0}
var daughter_data: Dictionary = {"name": "Анна", "relationship": 0}

func _ready() -> void:
    super._ready()
    npc_id = "vasily"
    npc_name = "Василий"
    behavior = BehaviorType.FIXED_ROUTE
    
    # Настройка диалогов
    setup_dialogues()
    
    # Проверка, встречались ли уже
    has_met_player = GameState.relationships.get(npc_id, 0) > 0

func setup_dialogues() -> void:
    dialogues = [
        {"mood": "cold", "text": "Чего надо? Я занят."},
        {"mood": "friendly", "text": "Привет! Как жизнь в лесу?"},
        {"mood": "thanked", "text": "Спасибо, дружище!"},
        {"mood": "first_meet", "text": "О, новый сосед? Я Василий, охочусь здесь. Домик твой видел, добротный."},
        {"mood": "offer_lift", "text": "Тебе до города? Ну садись, подвезу."},
        {"mood": "family", "text": "Заходи как-нибудь к нам, познакомлю с семьей."}
    ]

func _physics_process(_delta: float) -> void:
    if not has_met_player:
        check_first_meeting()
    else:
        super._physics_process(_delta)

func check_first_meeting() -> void:
    # Проверка, построен ли дом игрока
    if GameState.has_building("basic_house"):
        var distance = global_position.distance_to(player_home_position)
        if distance < 200.0:
            trigger_first_meeting()

func trigger_first_meeting() -> void:
    has_met_player = true
    GameState.set_relationship(npc_id, 15)  # Начальное отношение
    show_dialogue("first_meet")
    
    # Добавление начального квеста
    offer_starter_quest()

func offer_starter_quest() -> void:
    var quest = {
        "id": "vasily_intro",
        "type": "fetch",
        "item": "herbs",
        "amount": 3,
        "reward": 30,
        "description": "Собери 3 лечебных травы для моей жены"
    }
    active_quests.append(quest)
    quest_offered.emit(quest)

func offer_lift_to_town() -> void:
    if relationship >= 20:
        gives_lifts = true
        show_dialogue("offer_lift")
        # Здесь будет триггер сцены поездки в город
    else:
        show_dialogue("cold")

func introduce_family() -> void:
    if relationship >= 50 and not family_introduced:
        family_introduced = true
        show_dialogue("family")
        # Разблокировка встречи с семьей
        # Будет реализовано в сценах города

func get_unique_services() -> Array[String]:
    var services = []
    
    if relationship >= 20:
        services.append("lift_to_town")
    
    if relationship >= 40:
        services.append("hunting_tips")
    
    if relationship >= 60:
        services.append("meet_family")
    
    return services

func give_hunting_tips() -> void:
    # Советы по охоте
    var tips = [
        "Кабаны любят прятаться в густых кустах на рассвете.",
        "Олени осторожны, подходи с подветренной стороны.",
        "Лучшее время для охоты - раннее утро или вечер."
    ]
    print("[Василий]: ", tips[randi() % tips.size()])

func change_relationship(delta: int) -> void:
    super.change_relationship(delta)
    
    # Проверка порогов для новых возможностей
    if relationship >= 20 and not gives_lifts:
        gives_lifts = true
    
    if relationship >= 50 and not family_introduced:
        introduce_family()
