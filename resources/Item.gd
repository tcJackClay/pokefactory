extends Resource

## 道具数据类

@export_group("基础信息")
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

@export_group("类型")
@export var category: int = 0

@export_group("效果")
@export var hp_restore: int = 0
@export var pp_restore: int = 0
@export var status_heal: String = ""
@export var stat_boost: Dictionary = {}
@export var evolution_item: String = ""

@export_group("战斗使用")
@export var usable_in_battle: bool = false
@export var pocket: int = 0

@export_group("数值")
@export var price: int = 0
@export var sell_price: int = 0
@export var rarity: int = 1

const CATEGORY_CONSUMABLE = 0
const CATEGORY_POKEBALL = 1
const CATEGORY_ITEM = 2
const CATEGORY_TM = 3
const CATEGORY_MAIL = 4
const CATEGORY_BERRY = 5
const CATEGORY_EVOLUTION = 6

const POCKET_ITEMS = 0
const POCKET_POKEBALLS = 1
const POCKET_BERRIES = 2
const POCKET_TMS = 3
const POCKET_BATTLE = 4
const POCKET_MISC = 5


class Inventory:
	var items: Dictionary = {}
	
	func add_item(item_id: String, count: int = 1):
		if item_id in items:
			items[item_id] += count
		else:
			items[item_id] = count
	
	func remove_item(item_id: String, count: int = 1) -> bool:
		if item_id in items and items[item_id] >= count:
			items[item_id] -= count
			if items[item_id] <= 0:
				items.erase(item_id)
			return true
		return false
	
	func get_count(item_id: String) -> int:
		return items.get(item_id, 0)
	
	func has_item(item_id: String, count: int = 1) -> bool:
		return get_count(item_id) >= count
	
	func get_all_items() -> Array:
		return items.keys()
	
	func clear():
		items.clear()
	
	func to_dict() -> Dictionary:
		return items.duplicate(true)
	
	func from_dict(data: Dictionary):
		items = data.duplicate(true)


static func get_item_data(item_id: String) -> Dictionary:
	var db = load("res://scripts/ItemDB.gd").new()
	return db.get_item(item_id)


static func use_item_static(item_id: String, target) -> Dictionary:
	var item_data = get_item_data(item_id)
	if item_data.is_empty():
		return{"success": false, "message": "Unknown item"}
	
	if item_data.get("category") == CATEGORY_POKEBALL:
		return{"success": false, "message": "Cannot use Pokeball directly"}
	
	var result = {"success": true, "message": ""}
	
	# HP回复
	if item_data.get("hp_restore", 0) > 0 and target and target.has_method("heal"):
		target.heal(item_data.hp_restore)
		result.message = "Recovered %d HP!" % item_data.hp_restore
	
	# 状态治愈
	if item_data.get("status_heal", "") != "" and target:
		target.status = ""
		target.status_turns = 0
		result.message = "Status cured!"
	
	return result
