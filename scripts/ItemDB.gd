class_name ItemDB
extends Resource

## 道具数据库

@export var items: Dictionary = {}

func _init():
	load_data()

func load_data():
	var file = FileAccess.open("res://data/items.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			items = json.get_data()
		file.close()
		print("Loaded %d items" % items.size())
	else:
		printerr("Failed to load items.json")

func get_item(id: String) -> Dictionary:
	return items.get(id, {})

func get_item_count() -> int:
	return items.size()

func get_all_item_ids() -> Array:
	return items.keys()

func get_items_by_category(category: int) -> Array:
	var result: Array = []
	for id in items:
		if items[id].get("category") == category:
			result.append(id)
	return result

func get_pokeballs() -> Array:
	return get_items_by_category(1)

func get_consumables() -> Array:
	return get_items_by_category(0)

func get_berries() -> Array:
	return get_items_by_category(5)

func get_evolution_items() -> Array:
	return get_items_by_category(6)

func get_tms() -> Array:
	return get_items_by_category(3)

func search_items(query: String) -> Array:
	query = query.to_lower()
	var result: Array = []
	for id in items:
		var name = items[id].get("name", "").to_lower()
		if query in id or query in name:
			result.append(id)
	return result

# 道具分类常量
const CATEGORY_CONSUMABLE = 0
const CATEGORY_POKEBALL = 1
const CATEGORY_ITEM = 2
const CATEGORY_TM = 3
const CATEGORY_MAIL = 4
const CATEGORY_BERRY = 5
const CATEGORY_EVOLUTION = 6
