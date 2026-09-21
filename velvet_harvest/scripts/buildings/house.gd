extends Node2D
class_name House

enum BuildingStage { FOUNDATION, WALLS, ROOF, COMPLETE }

@export var current_stage: BuildingStage = BuildingStage.FOUNDATION
@export var wood_required: int = 50
@export var stone_required: int = 20
@export var nails_required: int = 30

var wood_collected: int = 0
var stone_collected: int = 0
var nails_collected: int = 0

@onready var foundation_sprite: ColorRect = $Foundation
@onready var walls_sprite: ColorRect = $Walls
@onready var roof_sprite: ColorRect = $Roof

signal stage_changed(new_stage)
signal construction_complete

func _ready():
	update_visuals()

func add_wood(amount: int):
	wood_collected += amount
	check_progress()

func add_stone(amount: int):
	stone_collected += amount
	check_progress()

func add_nails(amount: int):
	nails_collected += amount
	check_progress()

func check_progress():
	if current_stage == BuildingStage.FOUNDATION and wood_collected >= wood_required:
		current_stage = BuildingStage.WALLS
		emit_signal("stage_changed", current_stage)
	elif current_stage == BuildingStage.WALLS and stone_collected >= stone_required and nails_collected >= nails_required:
		current_stage = BuildingStage.ROOF
		emit_signal("stage_changed", current_stage)
	elif current_stage == BuildingStage.ROOF and wood_collected >= wood_required * 2:
		current_stage = BuildingStage.COMPLETE
		emit_signal("stage_changed", current_stage)
		emit_signal("construction_complete")
	
	update_visuals()

func update_visuals():
	match current_stage:
		BuildingStage.FOUNDATION:
			foundation_sprite.visible = true
			walls_sprite.visible = false
			roof_sprite.visible = false
		BuildingStage.WALLS:
			foundation_sprite.visible = true
			walls_sprite.visible = true
			roof_sprite.visible = false
		BuildingStage.ROOF:
			foundation_sprite.visible = true
			walls_sprite.visible = true
			roof_sprite.visible = true
		BuildingStage.COMPLETE:
			foundation_sprite.visible = true
			walls_sprite.visible = true
			roof_sprite.visible = true
			modulate = Color(1, 1, 1, 1)

func get_progress() -> float:
	match current_stage:
		BuildingStage.FOUNDATION:
			return float(wood_collected) / wood_required * 0.25
		BuildingStage.WALLS:
			return 0.25 + (float(stone_collected) / stone_required * 0.25) + (float(nails_collected) / nails_required * 0.25)
		BuildingStage.ROOF:
			return 0.75 + float(wood_collected) / (wood_required * 2) * 0.25
		BuildingStage.COMPLETE:
			return 1.0
	return 0.0
