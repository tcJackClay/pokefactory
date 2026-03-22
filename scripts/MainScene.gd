extends Node2D

@onready var root_ui: Control = $CanvasLayer/UI
@onready var message_label: Label = $CanvasLayer/UI/MessageLabel

var dashboard: BattleFactoryDashboard
var pokedex_screen: PokedexScreen
var current_screen: Control

func _ready() -> void:
	randomize()
	_hide_unused_legacy_ui()
	_setup_game_manager()
	_create_dashboard()
	_create_pokedex_screen()
	_load_background()
	_refresh_factory_ui()

func _hide_unused_legacy_ui() -> void:
	$CanvasLayer/UI/TopNav.visible = false
	$CanvasLayer/UI/BottomPanel.visible = false
	$CanvasLayer/UI/MenuButtonParent.visible = false
	$CanvasLayer/UI/MenuItemsPanel.visible = false

func _setup_game_manager() -> void:
	var gm = GameManager.get_instance()
	if not gm:
		gm = GameManager.new()
		add_child(gm)
	if not gm.load_game():
		gm.get_battle_factory_service().roll_starters()
	elif gm.get_battle_factory_service().get_state().get("starter_choices", []).is_empty() and not gm.get_battle_factory_service().get_state().get("run_active", false):
		gm.get_battle_factory_service().roll_starters()

func _create_dashboard() -> void:
	dashboard = BattleFactoryDashboard.new()
	dashboard.starter_selected.connect(_on_starter_selected)
	dashboard.recruit_selected.connect(_on_recruit_selected)
	dashboard.battle_requested.connect(_on_battle_pressed)
	dashboard.reset_requested.connect(_on_reset_pressed)
	dashboard.save_requested.connect(_on_save_pressed)
	dashboard.pokedex_requested.connect(show_pokedex)
	root_ui.add_child(dashboard)

func _create_pokedex_screen() -> void:
	pokedex_screen = PokedexScreen.new()
	pokedex_screen.visible = false
	pokedex_screen.setup(GameManager.get_instance())
	pokedex_screen.back_requested.connect(_on_back_pressed)
	root_ui.add_child(pokedex_screen)

func _refresh_factory_ui() -> void:
	var gm = GameManager.get_instance()
	dashboard.render(
		gm.get_battle_factory_service().get_state(),
		gm.get_team_members(),
		Callable(gm, "get_pokemon_data"),
		Callable(gm.get_battle_factory_service(), "get_bst_total")
	)
	if gm.get_battle_factory_service().get_state().get("run_active", false) and gm.get_battle_factory_service().get_state().get("win_streak", 0) >= gm.get_battle_factory_service().get_state().get("target_streak", 50):
		show_message("恭喜达成 50 连胜目标！", 2.0)

func _on_starter_selected(index: int) -> void:
	var service = GameManager.get_instance().get_battle_factory_service()
	var choices = service.get_state().get("starter_choices", [])
	if index >= choices.size():
		return
	service.start_run(choices[index])
	show_message("已选择初始宝可梦：%s" % GameManager.get_instance().get_pokemon_data(choices[index]).get("name", choices[index]), 1.5)
	_refresh_factory_ui()

func _on_recruit_selected(index: int) -> void:
	var service = GameManager.get_instance().get_battle_factory_service()
	var choices = service.get_state().get("recruit_choices", [])
	if index >= choices.size():
		return
	var result = service.accept_choice(choices[index])
	show_message(result.get("message", ""), 1.5)
	_refresh_factory_ui()

func _on_battle_pressed() -> void:
	var service = GameManager.get_instance().get_battle_factory_service()
	var result = service.simulate_battle()
	show_message(result.get("message", "进行了一场战斗模拟。"), 1.5)
	if result.get("success", false) and result.get("win", false):
		show_message("胜利！请从 3 只随机宝可梦中选择 1 只。", 1.5)
	elif result.get("success", false):
		service.reset_run()
		show_message("挑战失败，重新选择初始宝可梦开始下一轮。", 2.0)
	_refresh_factory_ui()

func _on_reset_pressed() -> void:
	GameManager.get_instance().get_battle_factory_service().reset_run()
	show_message("已重置对战工厂挑战。", 1.2)
	_refresh_factory_ui()

func show_pokedex() -> void:
	dashboard.visible = false
	pokedex_screen.visible = true
	current_screen = pokedex_screen

func _close_current_screen() -> void:
	if current_screen != null:
		current_screen.visible = false
		current_screen = null
	dashboard.visible = true

func _on_back_pressed() -> void:
	_close_current_screen()

func _on_save_pressed() -> void:
	GameManager.get_instance().save_game()
	show_message("Game Saved!", 1.0)

func show_message(text: String, duration: float = 2.0) -> void:
	message_label.text = text
	message_label.visible = text != ""
	if text != "" and duration > 0:
		await get_tree().create_timer(duration).timeout
		message_label.visible = false

func _load_background() -> void:
	var bg = $ParallaxBackground/BackgroundPattern
	var path = "res://assets/bg/main-bg.png"
	if ResourceLoader.exists(path):
		bg.texture = load(path)
		bg.modulate.a = 0.08

func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:
				if event.ctrl_pressed:
					GameManager.get_instance().save_game()
					show_message("Saved!", 1.0)
			KEY_ESCAPE:
				_close_current_screen()
