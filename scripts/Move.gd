class_name Move
extends Resource

## 技能数据类

@export_group("基础信息")
@export var id: String = ""
@export var name: String = ""
@export var type: String = "normal"

@export_group("战斗属性")
@export var category: int = 0  # 0=物理, 1=特殊, 2=变化
@export var power: int = 0
@export var accuracy: int = 100
@export var pp: int = 35
@export var max_pp: int = 57
@export var priority: int = 0

@export_group("效果")
@export var effect_chance: int = 0
@export var effect_status: String = ""  # burn, poison, paralysis, sleep, freeze
@export var effect_stat_change: Dictionary = {}  # {"atk": +1, "def": -1}
@export var effect_damage_percent: int = 0  # 固定伤害百分比

@export_group("其他")
@export var target: int = 0  # 0=敌人单体, 1=己方单体, 2=全体, 3=自身
@export var contact: bool = true
@export var protectable: bool = true
@export var counterable: bool = true
@export var mirrorable: bool = true
@export var snatchable: bool = false
@export var sound: bool = false
@export var punch: bool = false
@export var pulse: bool = false
@export var powder: bool = false
@export var restorable: bool = true  # 是否可以通过回忆恢复
@export var dirty: bool = false  # 脏技能（会导致PM变脏）
@export var not_usable_by_enemy: bool = false
@export var restricted: bool = false  # 限制技能，只能带一个
@export var moveset_tags: Array[String] = ["all"]  # 可学习标签
@export var rarity: int = 1  # 稀有度 1-3
@export var description: String = ""

# 常量
const CATEGORY_PHYSICAL = 0
const CATEGORY_SPECIAL = 1
const CATEGORY_STATUS = 2

const TARGET_ENEMY = 0
const TARGET_ALLY = 1
const TARGET_ALL = 2
const TARGET_SELF = 3

func get_category_string() -> String:
	match category:
		CATEGORY_PHYSICAL: return "Physical"
		CATEGORY_SPECIAL: return "Special"
		CATEGORY_STATUS: return "Status"
	return "Unknown"

func get_target_string() -> String:
	match target:
		TARGET_ENEMY: return "Enemy"
		TARGET_ALLY: return "Ally"
		TARGET_ALL: return "All"
		TARGET_SELF: return "Self"
	return "Unknown"

func is_damaging() -> bool:
	return category != CATEGORY_STATUS and power > 0


# 技能实例（战斗中实际使用的技能）
class MoveInstance:
	var id: String = ""
	var name: String = ""
	var type: String = "normal"
	var category: int = 0
	var power: int = 0
	var accuracy: int = 100
	var current_pp: int = 0
	var max_pp: int = 0
	var priority: int = 0
	var contact: bool = true
	var restricted: bool = false
	
	# 基础数据引用
	var base: Dictionary = {}
	
	func _init(move_id: String = ""):
		id = move_id
		if move_id != "":
			load_from_db(move_id)
	
	func load_from_db(move_id: String):
		var db = MoveDB.new()
		var move_data = db.get_move(move_id)
		if not move_data.is_empty():
			base = move_data
			name = move_data.get("id", move_id)
			type = move_data.get("type", "normal")
			category = move_data.get("category", 0)
			power = move_data.get("power", 0)
			accuracy = move_data.get("accuracy", 100)
			current_pp = move_data.get("pp", 35)
			max_pp = move_data.get("max_pp", 57)
			priority = move_data.get("priority", 0)
			contact = move_data.get("contact", true)
			restricted = move_data.get("restricted", false)
			name = move_data.name
			type = move_data.type
			category = move_data.category
			power = move_data.power
			accuracy = move_data.accuracy
			current_pp = move_data.pp
			max_pp = move_data.max_pp
			priority = move_data.priority
			contact = move_data.contact
			restricted = move_data.restricted
	
	func use() -> bool:
		if current_pp <= 0:
			return false
		current_pp -= 1
		return true
	
	func can_use() -> bool:
		return current_pp > 0
	
	func restore_pp(amount: int):
		current_pp = min(current_pp + amount, max_pp)
	
	func to_dict() -> Dictionary:
		return {
			"id": id,
			"current_pp": current_pp
		}
