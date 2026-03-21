class_name TypeEffectiveness
extends Node

## 属性相性计算类

# 属性相性表
# key: (attack_type, defend_type) -> multiplier
var effectiveness_chart: Dictionary = {
	# 正常系
	"normal": {"rock": 0.5, "ghost": 0.0, "steel": 0.5},
	
	# 火系
	"fire": {"fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 2.0, "bug": 2.0, 
			 "rock": 0.5, "dragon": 0.5, "steel": 2.0},
	
	# 水系
	"water": {"fire": 2.0, "water": 0.5, "grass": 0.5, "ground": 2.0, "rock": 2.0, "dragon": 0.5},
	
	# 草系
	"grass": {"fire": 0.5, "water": 2.0, "grass": 0.5, "poison": 0.5, "ground": 2.0,
			  "flying": 0.5, "bug": 0.5, "rock": 2.0, "dragon": 0.5, "steel": 0.5},
	
	# 电系
	"electric": {"water": 2.0, "electric": 0.5, "grass": 0.5, "ground": 0.0, "flying": 2.0, "dragon": 0.5},
	
	# 冰系
	"ice": {"fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 0.5, "ground": 2.0, 
			"flying": 2.0, "dragon": 2.0, "steel": 0.5},
	
	# 格斗系
	"fighting": {"normal": 2.0, "ice": 2.0, "poison": 0.5, "flying": 0.5, "psychic": 0.5,
				 "bug": 0.5, "rock": 2.0, "ghost": 0.0, "dark": 2.0, "steel": 2.0, "fairy": 0.5},
	
	# 毒系
	"poison": {"grass": 2.0, "poison": 0.5, "ground": 0.5, "rock": 0.5, "ghost": 0.5, "steel": 0.0, "fairy": 2.0},
	
	# 地面系
	"ground": {"fire": 2.0, "electric": 2.0, "grass": 0.5, "poison": 2.0, "flying": 0.0,
			  "bug": 0.5, "rock": 2.0, "steel": 2.0},
	
	# 飞行系
	"flying": {"electric": 0.5, "grass": 2.0, "fighting": 2.0, "bug": 2.0, "rock": 0.5, "steel": 0.5},
	
	# 超能力系
	"psychic": {"fighting": 2.0, "poison": 2.0, "psychic": 0.5, "dark": 0.0, "steel": 0.5},
	
	# 虫系
	"bug": {"fire": 0.5, "grass": 2.0, "fighting": 0.5, "poison": 0.5, "flying": 0.5, 
		   "psychic": 2.0, "ghost": 0.5, "dark": 2.0, "steel": 0.5, "fairy": 0.5},
	
	# 岩石系
	"rock": {"fire": 2.0, "ice": 2.0, "fighting": 0.5, "ground": 0.5, "flying": 2.0,
			"bug": 2.0, "steel": 0.5},
	
	# 幽灵系
	"ghost": {"psychic": 2.0, "ghost": 2.0, "dark": 0.5},
	
	# 龙系
	"dragon": {"dragon": 2.0, "steel": 0.5, "fairy": 0.0},
	
	# 恶系
	"dark": {"psychic": 2.0, "ghost": 2.0, "dark": 0.5, "fairy": 0.5},
	
	# 钢系
	"steel": {"fire": 0.5, "water": 0.5, "electric": 0.5, "ice": 2.0, "rock": 2.0, 
			  "steel": 0.5, "fairy": 2.0},
	
	# 妖精系
	"fairy": {"fire": 0.5, "fighting": 2.0, "poison": 0.5, "dragon": 2.0, "dark": 2.0, "steel": 0.5}
}

# 属性颜色
var type_colors: Dictionary = {
	"normal": Color("A8A77A"),
	"fire": "EE8130",
	"water": "6390F0",
	"electric": "F7D02C",
	"grass": "7AC74C",
	"ice": "96D9D6",
	"fighting": "C22E28",
	"poison": "A33EA1",
	"ground": "E2BF65",
	"flying": "A98FF3",
	"psychic": "F95587",
	"bug": "A6B91A",
	"rock": "B6A136",
	"ghost": "735797",
	"dragon": "6F35FC",
	"dark": "705746",
	"steel": "B7B7CE",
	"fairy": "D685AD"
}

# 属性中文名
var type_names_cn: Dictionary = {
	"normal": "一般",
	"fire": "火",
	"water": "水",
	"electric": "电",
	"grass": "草",
	"ice": "冰",
	"fighting": "格斗",
	"poison": "毒",
	"ground": "地面",
	"flying": "飞行",
	"psychic": "超能力",
	"bug": "虫",
	"rock": "岩石",
	"ghost": "幽灵",
	"dragon": "龙",
	"dark": "恶",
	"steel": "钢",
	"fairy": "妖精"
}

# 全部属性列表
var all_types: Array = [
	"normal", "fire", "water", "electric", "grass", "ice",
	"fighting", "poison", "ground", "flying", "psychic", "bug",
	"rock", "ghost", "dragon", "dark", "steel", "fairy"
]


func _ready():
	pass


## 计算属性相性
## attack_type: 攻击属性
## defend_types: 防御方属性数组
## 返回: 相性倍率
func get_effectiveness(attack_type: String, defend_types: Array) -> float:
	var multiplier = 1.0
	
	for defend_type in defend_types:
		multiplier *= _get_single_effectiveness(attack_type, defend_type)
	
	return multiplier


func _get_single_effectiveness(attack_type: String, defend_type: String) -> float:
	# 检查直接匹配
	if effectiveness_chart.has(attack_type):
		var type_data = effectiveness_chart[attack_type]
		if type_data.has(defend_type):
			return type_data[defend_type]
	
	# 默认1.0（无克制）
	return 1.0


## 获取属性颜色
func get_type_color(type_name: String) -> Color:
	if type_colors.has(type_name):
		return Color(type_colors[type_name])
	return Color.WHITE


## 获取中文名
func get_type_name_cn(type_name: String) -> String:
	return type_names_cn.get(type_name, type_name)


## 获取属性对某属性的克制表
func get_attacks_super_effective(attack_type: String) -> Array:
	var super_effective: Array = []
	
	for defend_type in all_types:
		if _get_single_effectiveness(attack_type, defend_type) > 1.0:
			super_effective.append(defend_type)
	
	return super_effective


func get_attacks_not_very_effective(attack_type: String) -> Array:
	var not_very_effective: Array = []
	
	for defend_type in all_types:
		if _get_single_effectiveness(attack_type, defend_type) < 1.0 and _get_single_effectiveness(attack_type, defend_type) > 0:
			not_very_effective.append(defend_type)
	
	return not_very_effective


func get_attacks_no_effect(attack_type: String) -> Array:
	var no_effect: Array = []
	
	for defend_type in all_types:
		if _get_single_effectiveness(attack_type, defend_type) == 0:
			no_effect.append(defend_type)
	
	return no_effect
