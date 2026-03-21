class_name UIManager
extends CanvasLayer

## UI管理器 - 单例
## 管理所有游戏UI界面

# 单例
static var instance: UIManager

# UI界面引用
var main_menu: Control
var team_menu: Control
var item_menu: Control
var pokedex_menu: Control
var battle_screen: Control
var explore_screen: Control
var shop_menu: Control
var settings_menu: Control
var tooltip_panel: Control

# 当前显示的界面
var current_screen: String = ""
var screen_stack: Array = []

# 主题颜色
var theme_colors: Dictionary = {
	"default": {
		"dark1": Color("#36342F"),
		"dark2": Color("#444138"),
		"light1": Color("#94886B"),
		"light2": Color("#ECDEB7"),
		"accent": Color("#ffe15e")
	},
	"dark": {
		"dark1": Color("#36342F"),
		"dark2": Color("#444138"),
		"light1": Color("#94886B"),
		"light2": Color("#ECDEB7")
	},
	"verdant": {
		"dark1": Color("#32493dff"),
		"dark2": Color("#475243ff"),
		"light1": Color("#94886B"),
		"light2": Color("#ECDEB7")
	}
}

var current_theme: String = "default"

func _ready():
	instance = self
	setup_ui()
	show_screen("main_menu")

func _init():
	if instance == null:
		instance = self

## 初始化UI
func setup_ui():
	# 创建所有UI界面
	create_main_menu()
	create_team_menu()
	create_item_menu()
	create_pokedex_menu()
	create_battle_screen()
	create_explore_screen()
	create_shop_menu()
	create_settings_menu()
	create_tooltip()

## 创建主菜单
func create_main_menu():
	main_menu = Control.new()
	main_menu.name = "MainMenu"
	main_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_menu.visible = true
	add_child(main_menu)
	
	# 顶部导航栏
	var top_nav = PanelContainer.new()
	top_nav.name = "TopNav"
	top_nav.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_nav.position = Vector2(0, 0)
	top_nav.custom_minimum_size = Vector2(0, 60)
	main_menu.add_child(top_nav)
	
	var nav_hbox = HBoxContainer.new()
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	nav_hbox.add_theme_constant_override("separation", 20)
	top_nav.add_child(nav_hbox)
	
	# 菜单按钮
	var menu_buttons = ["Travel", "Team", "Bag", "Pokedex", "Shop", "Settings"]
	for btn_name in menu_buttons:
		var btn = Button.new()
		btn.text = btn_name
		btn.pressed.connect(_on_menu_button_pressed.bind(btn_name))
		nav_hbox.add_child(btn)

## 创建队伍界面
func create_team_menu():
	team_menu = Control.new()
	team_menu.name = "TeamMenu"
	team_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	team_menu.visible = false
	add_child(team_menu)
	
	# 队伍标题栏
	var header = PanelContainer.new()
	header.name = "TeamHeader"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.position = Vector2(0, 0)
	header.custom_minimum_size = Vector2(0, 80)
	team_menu.add_child(header)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	header_hbox.add_theme_constant_override("separation", 10)
	header.add_child(header_hbox)
	
	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.pressed.connect(show_screen.bind("explore"))
	header_hbox.add_child(back_btn)
	
	# 队伍选择器
	var team_selector = OptionButton.new()
	team_selector.name = "TeamSelector"
	for i in range(1, 31):
		team_selector.add_item("Team %d" % i)
	header_hbox.add_child(team_selector)
	
	# 队伍槽位显示
	var team_grid = GridContainer.new()
	team_grid.name = "TeamGrid"
	team_grid.columns = 2
	team_grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	team_grid.position = Vector2(0, 80)
	team_grid.add_theme_constant_override("h_separation", 10)
	team_grid.add_theme_constant_override("v_separation", 10)
	team_menu.add_child(team_grid)
	
	# 6个队伍槽位
	for i in range(6):
		var slot_panel = create_team_slot(i)
		team_grid.add_child(slot_panel)

## 创建队伍槽位
func create_team_slot(index: int) -> PanelContainer:
	var slot = PanelContainer.new()
	slot.name = "TeamSlot_%d" % index
	slot.custom_minimum_size = Vector2(300, 120)
	
	var vbox = VBoxContainer.new()
	slot.add_child(vbox)
	
	# 宝可梦名称
	var name_label = Label.new()
	name_label.name = "SlotName"
	name_label.text = "Empty Slot"
	vbox.add_child(name_label)
	
	# 等级
	var level_label = Label.new()
	level_label.name = "SlotLevel"
	level_label.text = "Lv. 1"
	vbox.add_child(level_label)
	
	# HP条
	var hp_bar = ProgressBar.new()
	hp_bar.name = "SlotHP"
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.custom_minimum_size = Vector2(200, 20)
	vbox.add_child(hp_bar)
	
	# 技能显示
	var moves_hbox = HBoxContainer.new()
	moves_hbox.name = "SlotMoves"
	vbox.add_child(moves_hbox)
	
	for j in range(4):
		var move_label = Label.new()
		move_label.text = "-"
		moves_hbox.add_child(move_label)
	
	return slot

## 创建背包界面
func create_item_menu():
	item_menu = Control.new()
	item_menu.name = "ItemMenu"
	item_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_menu.visible = false
	add_child(item_menu)
	
	# 分类标签
	var category_tabs = TabContainer.new()
	category_tabs.name = "ItemTabs"
	category_tabs.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_menu.add_child(category_tabs)
	
	var categories = ["Items", "Pokeballs", "Berries", "TMs", "Key Items"]
	for cat in categories:
		var tab = ScrollContainer.new()
		tab.name = cat
		category_tabs.add_child(tab)
		
		var item_list = VBoxContainer.new()
		item_list.name = "ItemList"
		tab.add_child(item_list)

## 创建宝可梦图鉴
func create_pokedex_menu():
	pokedex_menu = Control.new()
	pokedex_menu.name = "PokedexMenu"
	pokedex_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pokedex_menu.visible = false
	add_child(pokedex_menu)
	
	# 搜索栏
	var search_bar = HBoxContainer.new()
	search_bar.name = "SearchBar"
	search_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	search_bar.position = Vector2(0, 0)
	search_bar.custom_minimum_size = Vector2(0, 50)
	pokedex_menu.add_child(search_bar)
	
	var search_input = LineEdit.new()
	search_input.name = "SearchInput"
	search_input.placeholder_text = "Search Pokemon..."
	search_bar.add_child(search_input)
	
	# 筛选器
	var filter_container = HBoxContainer.new()
	filter_container.name = "Filters"
	filter_container.position = Vector2(0, 50)
	filter_container.custom_minimum_size = Vector2(0, 40)
	pokedex_menu.add_child(filter_container)
	
	# 图鉴列表
	var pokedex_grid = GridContainer.new()
	pokedex_grid.name = "PokedexGrid"
	pokedex_grid.columns = 5
	pokedex_grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	pokedex_grid.position = Vector2(0, 90)
	pokedex_grid.add_theme_constant_override("h_separation", 5)
	pokedex_grid.add_theme_constant_override("v_separation", 5)
	pokedex_menu.add_child(pokedex_grid)

## 创建战斗界面
func create_battle_screen():
	battle_screen = Control.new()
	battle_screen.name = "BattleScreen"
	battle_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_screen.visible = false
	add_child(battle_screen)
	
	# 敌方宝可梦区域 (上半部分)
	var enemy_area = PanelContainer.new()
	enemy_area.name = "EnemyArea"
	enemy_area.set_anchors_preset(Control.PRESET_TOP_WIDE)
	enemy_area.custom_minimum_size = Vector2(0, 200)
	battle_screen.add_child(enemy_area)
	
	# 敌方信息
	var enemy_info = VBoxContainer.new()
	enemy_info.name = "EnemyInfo"
	enemy_area.add_child(enemy_info)
	
	var enemy_name = Label.new()
	enemy_name.name = "EnemyName"
	enemy_name.text = "Wild Pokemon"
	enemy_info.add_child(enemy_name)
	
	var enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.name = "EnemyHP"
	enemy_hp_bar.max_value = 100
	enemy_hp_bar.value = 100
	enemy_info.add_child(enemy_hp_bar)
	
	# 玩家宝可梦区域 (下半部分)
	var player_area = PanelContainer.new()
	player_area.name = "PlayerArea"
	player_area.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	player_area.custom_minimum_size = Vector2(0, 300)
	player_area.position = Vector2(0, 300)
	battle_screen.add_child(player_area)
	
	# 玩家信息
	var player_info = VBoxContainer.new()
	player_info.name = "PlayerInfo"
	player_area.add_child(player_info)
	
	var player_name = Label.new()
	player_name.name = "PlayerName"
	player_name.text = "Your Pokemon"
	player_info.add_child(player_name)
	
	var player_hp_bar = ProgressBar.new()
	player_hp_bar.name = "PlayerHP"
	player_hp_bar.max_value = 100
	player_hp_bar.value = 100
	player_info.add_child(player_hp_bar)
	
	# 技能按钮区域
	var moves_panel = GridContainer.new()
	moves_panel.name = "MovesPanel"
	moves_panel.columns = 2
	moves_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	moves_panel.custom_minimum_size = Vector2(0, 150)
	moves_panel.position = Vector2(0, 450)
	battle_screen.add_child(moves_panel)
	
	# 4个技能按钮
	for i in range(4):
		var move_btn = Button.new()
		move_btn.name = "Move_%d" % i
		move_btn.text = "Move %d" % (i + 1)
		move_btn.custom_minimum_size = Vector2(200, 60)
		moves_panel.add_child(move_btn)

## 创建探索界面
func create_explore_screen():
	explore_screen = Control.new()
	explore_screen.name = "ExploreScreen"
	explore_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	explore_screen.visible = false
	add_child(explore_screen)
	
	# 区域信息
	var area_info = PanelContainer.new()
	area_info.name = "AreaInfo"
	area_info.set_anchors_preset(Control.PRESET_TOP_WIDE)
	area_info.custom_minimum_size = Vector2(0, 60)
	explore_screen.add_child(area_info)
	
	var area_label = Label.new()
	area_label.name = "AreaName"
	area_label.text = "Area Name"
	area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area_info.add_child(area_label)
	
	# 探索按钮
	var explore_vbox = VBoxContainer.new()
	explore_vbox.name = "ExploreActions"
	explore_vbox.set_anchors_preset(Control.PRESET_CENTER)
	explore_vbox.position = Vector2(-100, -50)
	explore_vbox.custom_minimum_size = Vector2(200, 100)
	explore_screen.add_child(explore_vbox)
	
	var explore_btn = Button.new()
	explore_btn.text = "Explore!"
	explore_btn.custom_minimum_size = Vector2(200, 60)
	explore_btn.pressed.connect(_on_explore_pressed)
	explore_vbox.add_child(explore_btn)

## 创建商店界面
func create_shop_menu():
	shop_menu = Control.new()
	shop_menu.name = "ShopMenu"
	shop_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_menu.visible = false
	add_child(shop_menu)
	
	# 商店标题
	var shop_title = Label.new()
	shop_title.name = "ShopTitle"
	shop_title.text = "Shop"
	shop_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	shop_title.position = Vector2(0, 10)
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_menu.add_child(shop_title)
	
	# 商品列表
	var shop_grid = GridContainer.new()
	shop_grid.name = "ShopGrid"
	shop_grid.columns = 2
	shop_grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_grid.position = Vector2(0, 50)
	shop_grid.add_theme_constant_override("h_separation", 10)
	shop_grid.add_theme_constant_override("v_separation", 10)
	shop_menu.add_child(shop_grid)

## 构建设置界面
func create_settings_menu():
	settings_menu = Control.new()
	settings_menu.name = "SettingsMenu"
	settings_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_menu.visible = false
	add_child(settings_menu)
	
	var settings_vbox = VBoxContainer.new()
	settings_vbox.name = "SettingsVBox"
	settings_vbox.set_anchors_preset(Control.PRESET_CENTER)
	settings_vbox.custom_minimum_size = Vector2(300, 200)
	settings_menu.add_child(settings_vbox)
	
	# 主题选择
	var theme_label = Label.new()
	theme_label.text = "Theme"
	settings_vbox.add_child(theme_label)
	
	var theme_selector = OptionButton.new()
	theme_selector.name = "ThemeSelector"
	theme_selector.add_item("Default")
	theme_selector.add_item("Dark")
	theme_selector.add_item("Verdant")
	theme_selector.add_item("Lilac")
	theme_selector.add_item("Cherry")
	theme_selector.add_item("Coral")
	theme_selector.item_selected.connect(_on_theme_changed)
	settings_vbox.add_child(theme_selector)
	
	# 音量控制
	var volume_label = Label.new()
	volume_label.text = "Music Volume"
	settings_vbox.add_child(volume_label)
	
	var volume_slider = HSlider.new()
	volume_slider.name = "VolumeSlider"
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = 80
	settings_vbox.add_child(volume_slider)
	
	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(show_screen.bind("main_menu"))
	settings_vbox.add_child(back_btn)

## 创建提示框
func create_tooltip():
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "Tooltip"
	tooltip_panel.set_anchors_preset(Control.PRESET_CENTER)
	tooltip_panel.visible = false
	add_child(tooltip_panel)
	
	var tooltip_label = Label.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.text = "Tooltip"
	tooltip_panel.add_child(tooltip_label)

## 显示界面
func show_screen(screen_name: String):
	# 隐藏所有界面
	hide_all_screens()
	
	# 显示目标界面
	match screen_name:
		"main_menu":
			main_menu.visible = true
		"team":
			team_menu.visible = true
			update_team_display()
		"bag", "item":
			item_menu.visible = true
		"pokedex":
			pokedex_menu.visible = true
			update_pokedex_display()
		"battle":
			battle_screen.visible = true
		"explore":
			explore_screen.visible = true
		"shop":
			shop_menu.visible = true
		"settings":
			settings_menu.visible = true
	
	current_screen = screen_name

## 隐藏所有界面
func hide_all_screens():
	if main_menu: main_menu.visible = false
	if team_menu: team_menu.visible = false
	if item_menu: item_menu.visible = false
	if pokedex_menu: pokedex_menu.visible = false
	if battle_screen: battle_screen.visible = false
	if explore_screen: explore_screen.visible = false
	if shop_menu: shop_menu.visible = false
	if settings_menu: settings_menu.visible = false
	if tooltip_panel: tooltip_panel.visible = false

## 显示提示框
func show_tooltip(text: String, position: Vector2 = Vector2.ZERO):
	tooltip_panel.visible = true
	var label = tooltip_panel.get_node("TooltipLabel")
	label.text = text
	
	if position != Vector2.ZERO:
		tooltip_panel.position = position
	else:
		tooltip_panel.set_anchors_preset(Control.PRESET_CENTER)

## 隐藏提示框
func hide_tooltip():
	tooltip_panel.visible = false

## 更新队伍显示
func update_team_display():
	if not team_menu: return
	
	var team = GameManager.get_instance().player_team.get_team()
	var grid = team_menu.get_node("TeamGrid")
	if not grid: return
	
	for i in range(6):
		var slot = grid.get_child(i)
		if slot and i < team.slots.size():
			var pkmn = team.slots[i].pokemon
			var name_label = slot.get_node("SlotName")
			var level_label = slot.get_node("SlotLevel")
			var hp_bar = slot.get_node("SlotHP")
			
			if pkmn:
				name_label.text = pkmn.base.get("name", "Unknown") if pkmn.base else "Unknown"
				level_label.text = "Lv. %d" % pkmn.level
				hp_bar.max_value = pkmn.max_hp
				hp_bar.value = pkmn.current_hp
			else:
				name_label.text = "Empty Slot"
				level_label.text = "-"
				hp_bar.max_value = 100
				hp_bar.value = 0

## 更新图鉴显示
func update_pokedex_display():
	if not pokedex_menu: return
	
	var grid = pokedex_grid()
	if not grid: return
	
	grid.get_children().map(func(c): c.free())
	
	var db = GameManager.get_pokemon_db()
	var all_pokemon = db.get_all_pokemon_ids()
	
	for pkmn_id in all_pokemon:
		var pkmn_data = db.get_pokemon(pkmn_id)
		var pkmn_btn = create_pokedex_entry(pkmn_id, pkmn_data)
		grid.add_child(pkmn_btn)

## 创建图鉴条目
func create_pokedex_entry(pkmn_id: String, data: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	
	var vbox = VBoxContainer.new()
	btn.add_child(vbox)
	
	var sprite = TextureRect.new()
	sprite.name = "Sprite"
	sprite.custom_minimum_size = Vector2(60, 60)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vbox.add_child(sprite)
	
	var name_label = Label.new()
	name_label.text = data.get("name", pkmn_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)
	
	return btn

## 更新背包显示
func update_item_display():
	if not item_menu: return
	# TODO: 实现背包更新

## 更新战斗UI
func update_battle_ui(player_pkmn: Pokemon.PokemonInstance, enemy_pkmn: Pokemon.PixelInstance):
	if not battle_screen: return
	
	# 更新玩家信息
	var player_name = battle_screen.get_node("PlayerArea/PlayerInfo/PlayerName")
	var player_hp = battle_screen.get_node("PlayerArea/PlayerInfo/PlayerHP")
	if player_pkmn:
		player_name.text = player_pkmn.base.get("name", "Unknown") if player_pkmn.base else "Unknown"
		player_hp.max_value = player_pkmn.max_hp
		player_hp.value = player_pkmn.current_hp
	
	# 更新敌人信息
	var enemy_name = battle_screen.get_node("EnemyArea/EnemyInfo/EnemyName")
	var enemy_hp = battle_screen.get_node("EnemyArea/EnemyInfo/EnemyHP")
	if enemy_pkmn:
		enemy_name.text = enemy_pkmn.base.get("name", "Unknown") if enemy_pkmn.base else "Unknown"
		enemy_hp.max_value = enemy_pkmn.max_hp
		enemy_hp.value = enemy_pkmn.current_hp

## 信号处理
func _on_menu_button_pressed(button_name: String):
	match button_name:
		"Travel":
			show_screen("explore")
		"Team":
			show_screen("team")
		"Bag":
			show_screen("bag")
		"Pokedex":
			show_screen("pokedex")
		"Shop":
			show_screen("shop")
		"Settings":
			show_screen("settings")

func _on_explore_pressed():
	show_screen("battle")

func _on_theme_changed(index: int):
	var themes = ["default", "dark", "verdant", "lilac", "cherry", "coral"]
	current_theme = themes[index]
	apply_theme(current_theme)

## 应用主题
func apply_theme(theme_name: String):
	if theme_colors.has(theme_name):
		var colors = theme_colors[theme_name]
		# 应用主题颜色到所有界面
		# TODO: 实现主题应用


# 静态方法
static func get_instance() -> UIManager:
	return instance

static func show(screen_name: String):
	if instance:
		instance.show_screen(screen_name)

static func display_tooltip(text: String, position: Vector2 = Vector2.ZERO):
	if instance:
		instance.show_tooltip(text, position)

static func hide_tooltip():
	if instance:
		instance.hide_tooltip()
