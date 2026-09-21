extends CanvasLayer
## UI менеджера

@onready var melons_label: Label = $MarginContainer/VBoxContainer/MelonsLabel if has_node("MarginContainer/VBoxContainer/MelonsLabel") else null
@onready var day_label: Label = $MarginContainer/VBoxContainer/DayLabel if has_node("MarginContainer/VBoxContainer/DayLabel") else null
@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel if has_node("MarginContainer/VBoxContainer/TimeLabel") else null

var ui_visible: bool = true

func _ready() -> void:
    GameState.melons_changed.connect(_on_melons_changed)
    GameState.day_changed.connect(_on_day_changed)
    GameState.time_changed.connect(_on_time_changed)
    update_all()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        toggle_ui()

func update_all() -> void:
    update_melons()
    update_day()
    update_time()

func update_melons() -> void:
    if melons_label:
        melons_label.text = "Мелоны: %d" % GameState.melons

func update_day() -> void:
    if day_label:
        day_label.text = "День %d" % GameState.current_day

func update_time() -> void:
    if time_label:
        var hour = int(GameState.current_time)
        var minute = int((GameState.current_time - hour) * 60)
        time_label.text = "%02d:%02d" % [hour, minute]

func _on_melons_changed(_new_amount: int) -> void:
    update_melons()

func _on_day_changed(_new_day: int) -> void:
    update_day()

func _on_time_changed(_new_time: float) -> void:
    update_time()

func toggle_ui() -> void:
    ui_visible = not ui_visible
    visible = ui_visible

func show_notification(message: String) -> void:
    print("[UI]: ", message)

func show_dialogue(npc_name: String, text: String, choices: Array[String] = []) -> void:
    print("[", npc_name, "]: ", text)
    if not choices.is_empty():
        for i in range(choices.size()):
            print("%d. %s" % [i + 1, choices[i]])

func show_inventory() -> void:
    print("Инвентарь:")
    for item in GameState.inventory:
        print("- ", item, ": ", GameState.inventory[item])
