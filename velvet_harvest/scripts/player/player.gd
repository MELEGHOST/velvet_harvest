class_name PlayerCharacter
extends CharacterBody2D
## Игрок

@export var speed: float = 200.0
@export var sprint_multiplier: float = 1.5

var is_sprinting: bool = false
var is_building_mode: bool = false
var current_tool: String = "axe_basic"
var carrying_item: String = ""

signal tool_changed(new_tool: String)
signal item_picked_up(item_id: String)
signal building_mode_toggled(is_active: bool)

func _physics_process(delta: float) -> void:
    var input_vector = Vector2.ZERO
    
    # Движение
    input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    
    # Спринт
    is_sprinting = Input.is_key_pressed(KEY_SHIFT)
    var current_speed = speed * (sprint_multiplier if is_sprinting else 1.0)
    
    if input_vector != Vector2.ZERO:
        input_vector = input_vector.normalized()
    
    velocity = input_vector * current_speed
    move_and_slide()
    
    # Взаимодействие
    if Input.is_action_just_pressed("interact"):
        interact()
    
    # Режим строительства
    if Input.is_action_just_pressed("build_mode"):
        toggle_build_mode()

func interact() -> void:
    # Проверка взаимодействия с объектами вокруг
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsRayQueryParameters2D.create(
        global_position,
        global_position + Vector2.RIGHT * 64.0,  # Дистанция взаимодействия
        ["world", "buildings", "crops"]
    )
    
    var result = space_state.intersect_ray(query)
    if result:
        var collider = result.collider
        if collider.has_method("interact"):
            collider.interact()

func toggle_build_mode() -> void:
    is_building_mode = not is_building_mode
    building_mode_toggled.emit(is_building_mode)

func pick_up_item(item_id: String) -> void:
    carrying_item = item_id
    item_picked_up.emit(item_id)

func drop_item() -> void:
    carrying_item = ""

func use_tool(target: Node2D) -> void:
    match current_tool:
        "axe_basic":
            if target.is_in_group("trees"):
                chop_tree(target)
        "pickaxe_basic":
            if target.is_in_group("rocks"):
                mine_rock(target)
        "hoe_basic":
            if target.is_in_group("soil"):
                till_soil(target)
        "watering_can":
            if target.is_in_group("crops"):
                water_crop(target)

func chop_tree(tree: Node2D) -> void:
    if tree.has_method("take_damage"):
        tree.take_damage(25.0)  # Урон топором

func mine_rock(rock: Node2D) -> void:
    if rock.has_method("take_damage"):
        rock.take_damage(15.0)  # Урон киркой

func till_soil(soil: Node2D) -> void:
    if soil.has_method("till"):
        soil.till()

func water_crop(crop: CropPlot) -> void:
    crop.water(0.3)

func change_tool(new_tool: String) -> void:
    current_tool = new_tool
    tool_changed.emit(new_tool)

func get_inventory() -> Dictionary:
    return GameState.inventory

func add_to_inventory(item_id: String, amount: int = 1) -> void:
    GameState.add_to_inventory(item_id, amount)
    item_picked_up.emit(item_id)
