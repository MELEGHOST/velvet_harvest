class_name NPCCharacter
extends CharacterBody2D
## Базовый NPC

@export var npc_id: String
@export var npc_name: String
@export var relationship: int = 0

# Поведение
enum BehaviorType { IDLE, WANDER, FOLLOW, FIXED_ROUTE }
@export var behavior: BehaviorType = BehaviorType.WANDER

# Маршруты для фиксированного поведения
@export var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0

# Диалоги
@export var dialogues: Array[Dictionary] = []
var current_dialogue_index: int = 0

# Квесты и заказы
var active_quests: Array[Dictionary] = []
var completed_quests: Array[String] = []

signal relationship_changed(new_value: int)
signal quest_offered(quest: Dictionary)
signal quest_completed(quest_id: String)

func _ready() -> void:
	if GameState.relationships.has(npc_id):
		relationship = GameState.relationships[npc_id]

func _physics_process(_delta: float) -> void:
	match behavior:
		BehaviorType.WANDER:
			wander()
		BehaviorType.FOLLOW:
			pass  # Будет реализовано позже
		BehaviorType.FIXED_ROUTE:
			follow_route()

func wander() -> void:
	# Простое блуждание вокруг текущей позиции
	if randf() < 0.02:  # 2% шанс каждый кадр сменить направление
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		velocity = direction * 50.0
		move_and_slide()

func follow_route() -> void:
	if waypoints.is_empty():
		return
	
	var target = waypoints[current_waypoint_index]
	var direction = (target - global_position).normalized()
	
	if global_position.distance_to(target) < 10.0:
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
	else:
		velocity = direction * 80.0
		move_and_slide()

func interact(player: Node2D) -> void:
	# Проверка отношения
	if relationship < 10:
		show_dialogue("cold")
	else:
		show_dialogue("friendly")
	
	# Предложение квеста
	if can_offer_quest():
		offer_quest()

func show_dialogue(mood: String) -> void:
	var dialogue = get_dialogue_for_mood(mood)
	if dialogue:
		# Здесь будет вызов UI диалога
		print("[", npc_name, "]: ", dialogue.get("text", "..."))

func get_dialogue_for_mood(mood: String) -> Dictionary:
	for d in dialogues:
		if d.get("mood") == mood:
			return d
	return {"text": "..."}

func can_offer_quest() -> bool:
	return relationship >= 30 and active_quests.size() < 2

func offer_quest() -> void:
	# Генерация простого квеста
	var quest = generate_quest()
	if quest:
		active_quests.append(quest)
		quest_offered.emit(quest)

func generate_quest() -> Dictionary:
	var quest_types = ["fetch", "deliver", "hunt"]
	var quest_type = quest_types[randi() % quest_types.size()]
	
	match quest_type:
		"fetch":
			return {
				"id": "fetch_" + str(Time.get_ticks_msec()),
				"type": "fetch",
				"item": "herbs",
				"amount": randi_range(3, 5),
				"reward": randi_range(20, 50)
			}
		"hunt":
			return {
				"id": "hunt_" + str(Time.get_ticks_msec()),
				"type": "hunt",
				"target": "boar",
				"amount": randi_range(1, 2),
				"reward": randi_range(30, 60)
			}
	
	return {}

func complete_quest(quest_id: String) -> bool:
	for i in range(active_quests.size()):
		if active_quests[i].id == quest_id:
			var quest = active_quests[i]
			active_quests.remove_at(i)
			completed_quests.append(quest_id)
			
			# Награда
			GameState.add_melons(quest.reward)
			change_relationship(5)
			
			quest_completed.emit(quest_id)
			return true
	
	return false

func change_relationship(delta: int) -> void:
	relationship = clamp(relationship + delta, 0, 100)
	GameState.set_relationship(npc_id, relationship)
	relationship_changed.emit(relationship)

func give_gift(item_id: String) -> void:
	# Реакция на подарок
	var gift_value = get_gift_value(item_id)
	change_relationship(gift_value)
	show_dialogue("thanked")

func get_gift_value(item_id: String) -> int:
	# Простая система оценки подарков
	match item_id:
		"rare_flower", "golden_crop":
			return 10
		"common_crop", "wood":
			return 2
		"trash":
			return -5
	return 5
