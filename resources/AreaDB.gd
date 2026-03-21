class_name AreaDB
extends Resource

## 区域数据库

@export var areas: Dictionary = {}

func _init():
	load_data()

func load_data():
	var file = FileAccess.open("res://data/areas.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			areas = json.get_data()
		file.close()
		print("Loaded %d areas" % areas.size())
	else:
		printerr("Failed to load areas.json")

func get_area(id: String) -> Dictionary:
	return areas.get(id, {})

func get_area_count() -> int:
	return areas.size()

func get_all_area_ids() -> Array:
	return areas.keys()

func get_areas_by_type(area_type: String) -> Array:
	var result: Array = []
	for id in areas:
		if areas[id].get("type") == area_type:
			result.append(id)
	return result

func get_wild_areas() -> Array:
	return get_areas_by_type("wild")

func get_vs_areas() -> Array:
	return get_areas_by_type("vs")

func get_dungeon_areas() -> Array:
	return get_areas_by_type("dungeon")

func get_frontier_areas() -> Array:
	return get_areas_by_type("frontier")

func get_training_areas() -> Array:
	return get_areas_by_type("training")

func get_areas_by_level(min_level: int, max_level: int) -> Array:
	var result: Array = []
	for id in areas:
		var area_min = areas[id].get("level_min", 1)
		var area_max = areas[id].get("level_max", 100)
		if area_min <= max_level and area_max >= min_level:
			result.append(id)
	return result

func search_areas(query: String) -> Array:
	query = query.to_lower()
	var result: Array = []
	for id in areas:
		var name = areas[id].get("name", "").to_lower()
		if query in id or query in name:
			result.append(id)
	return result

# 区域类型常量
const TYPE_WILD = "wild"
const TYPE_VS = "vs"
const TYPE_DUNGEON = "dungeon"
const TYPE_FRONTIER = "frontier"
const TYPE_TRAINING = "training"
const TYPE_EVENT = "event"
