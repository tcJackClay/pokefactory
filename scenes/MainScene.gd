extends Node2D

## 主场景 - 游戏的入口点

@onready var game_manager: Node
var ui_manager: UIManager

func _ready():
	# 初始化游戏
	setup_game()
	
	# 初始化UI管理器
	ui_manager = UIManager.new()
	add_child(ui_manager)
	
	# 显示主菜单
	ui_manager.show_screen("main_menu")

func setup_game():
	# 确保GameManager已初始化
	var gm = GameManager.get_instance()
	if not gm:
		gm = GameManager.new()
		add_child(gm)
	
	# 加载存档或创建新游戏
	var gm_instance = GameManager.get_instance()
	if gm_instance.load_game():
		print("Save file loaded")
	else:
		print("New game started")
		start_new_game()

func start_new_game():
	# 创建初始队伍
	var gm = GameManager.get_instance()
	
	# 添加一些初始宝可梦
	gm.add_pokemon_to_team("bulbasaur", 5)
	gm.add_pokemon_to_team("charmander", 5)
	gm.add_pokemon_to_team("squirtle", 5)
	
	# 设置初始区域
	gm.current_area = "verdant_forest"

func _process(delta):
	# 游戏循环更新
	pass

func _input(event):
	# 处理输入
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_ESCAPE:
					# 返回主菜单
					ui_manager.show_screen("main_menu")
				KEY_S:
					# 快速存档
					if event.ctrl_pressed:
						GameManager.get_instance().save_game()
				KEY_L:
					# 快速读档
					if event.ctrl_pressed:
						GameManager.get_instance().load_game()
