class_name Area
extends Resource

## 区域数据类

@export_group("基础信息")
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

@export_group("类型")
@export var area_type: int = 0  # 0=wild, 1=vs, 2=dungeon, 3=frontier, 4=training, 5=event
@export var level_min: int = 1
@export var level_max: int = 100

@export_group("特征")
@export var has_trainers: bool = false
@export var has_bosses: bool = false
@export var rotation_enabled: bool = false
@export var required_division: int = 0  # 所需段位
@export var required_items: Array[String] = []

@export_group("奖励")
@export var rewards: Dictionary = {}  # {"money": 100, "exp": 50}
@export var available_items: Array[String] = []  # 可获得的道具

# 区域类型常量
const TYPE_WILD = 0      # 野生战斗
const TYPE_VS = 1        # 训练家对战
const TYPE_DUNGEON = 2   # 地下城
const TYPE_FRONTIER = 3  # 挑战设施
const TYPE_TRAINING = 4  # 训练区
const TYPE_EVENT = 5     # 活动区域


# 区域实例
class AreaInstance:
	var id: String = ""
	var name: String = ""
	var area_type: int = 0
	var level_min: int = 1
	var level_max: int = 100
	var current_rotation: int = 1
	var is_unlocked: bool = false
	var defeated_trainers: Array[String] = []
	var cleared: bool = false
	
	func _init(area: Area = null):
		if area:
			id = area.id
			name = area.name
			area_type = area.area_type
			level_min = area.level_min
			level_max = area.level_max
	
	func get_random_level() -> int:
		return randi() % (level_max - level_min + 1) + level_min
	
	func get_pokemon_pool() -> Array:
		# TODO: 根据区域和轮换返回宝可梦列表
		return []


# 区域管理器
class AreaManager:
	static var areas: Dictionary = {}  # {area_id: Area}
	static var current_area: AreaInstance = null
	static var area_states: Dictionary = {}  # 保存区域状态
	
	static func init_areas():
		# TODO: 从数据文件加载所有区域
		pass
	
	static func get_area(area_id: String) -> Area:
		return areas.get(area_id)
	
	static func set_current_area(area_id: String):
		var area = areas.get(area_id)
		if area:
			current_area = AreaInstance.new(area)
	
	static func unlock_area(area_id: String):
		if area_id in area_states:
			area_states[area_id]["unlocked"] = true
	
	static func is_area_unlocked(area_id: String) -> bool:
		return area_states.get(area_id, {}).get("unlocked", false)
	
	static func save_area_states() -> Dictionary:
		return area_states.duplicate(true)
	
	static func load_area_states(data: Dictionary):
		area_states = data.duplicate(true)


# 区域数据示例
static func create_sample_areas() -> Dictionary:
	var sample_areas: Dictionary = {}
	
	# 森林
	var forest = Area.new()
	forest.id = "verdant_forest"
	forest.name = "Verdant Forest"
	forest.description = "A lush forest with many Pokemon"
	forest.area_type = TYPE_WILD
	forest.level_min = 1
	forest.level_max = 15
	forest.has_trainers = true
	sample_areas[forest.id] = forest
	
	# 洞穴
	var cave = Area.new()
	cave.id = "rocky_cave"
	cave.name = "Rocky Cave"
	cave.description = "A dark cave filled with rock types"
	cave.area_type = TYPE_WILD
	cave.level_min = 10
	cave.level_max = 30
	cave.has_trainers = true
	sample_areas[cave.id] = cave
	
	# 水系区域
	var lake = Area.new()
	lake.id = "mystic_lake"
	lake.name = "Mystic Lake"
	lake.description = "A beautiful lake with water Pokemon"
	lake.area_type = TYPE_WILD
	lake.level_min = 5
	lake.level_max = 25
	sample_areas[lake.id] = lake
	
	# 训练场
	var training = Area.new()
	training.id = "training_ground"
	training.name = "Training Ground"
	training.description = "Train your Pokemon here"
	training.area_type = TYPE_TRAINING
	training.level_min = 1
	training.level_max = 100
	sample_areas[training.id] = training
	
	# 挑战设施
	var frontier = Area.new()
	frontier.id = "battle_frontier"
	frontier.name = "Battle Frontier"
	frontier.description = "Test your skills"
	frontier.area_type = TYPE_FRONTIER
	frontier.level_min = 50
	frontier.level_max = 100
	frontier.has_trainers = true
	frontier.required_division = 1
	sample_areas[frontier.id] = frontier
	
	return sample_areas
