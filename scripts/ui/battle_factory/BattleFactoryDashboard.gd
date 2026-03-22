class_name BattleFactoryDashboard
extends ScrollContainer

signal starter_selected(index: int)
signal recruit_selected(index: int)
signal battle_requested
signal reset_requested
signal save_requested
signal pokedex_requested

const CARD_BG = Color("2B2D42")
const ACCENT = Color("E9C46A")

var content_box: VBoxContainer
var starter_buttons: Array[Button] = []
var team_cards: Array[PanelContainer] = []
var recruit_buttons: Array[Button] = []
var opponent_cards: Array[PanelContainer] = []
var log_label: RichTextLabel
var streak_label: Label
var status_label: Label
var picker_hint: Label
var battle_button: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 12
	offset_top = 12
	offset_right = -12
	offset_bottom = -12
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build_ui()

func render(factory_state: Dictionary, team_members: Array, pokemon_provider, bst_provider: Callable) -> void:
	streak_label.text = "当前连胜 %d · 最佳 %d · 目标 %d" % [factory_state.get("win_streak", 0), factory_state.get("best_streak", 0), factory_state.get("target_streak", 50)]
	status_label.text = "手机竖屏工厂模式：初始 1 只，胜利后从随机 3 选 1，保持 3 人队冲击 50 连胜。当前队伍 %d/3。" % team_members.size()
	picker_hint.text = "保留宝可梦数据、图形、升级/进化与属性克制。界面按手机单手操作重排。"
	_update_starter_buttons(factory_state.get("starter_choices", []), factory_state.get("run_active", false), pokemon_provider, bst_provider)
	_update_team_cards(team_members, bst_provider)
	_update_recruit_buttons(factory_state.get("recruit_choices", []), pokemon_provider, bst_provider)
	_update_opponent_preview(factory_state.get("opponent_preview", []), bst_provider)
	_update_log(factory_state.get("log", []))
	battle_button.disabled = not factory_state.get("run_active", false) or not factory_state.get("recruit_choices", []).is_empty()

func _build_ui() -> void:
	content_box = VBoxContainer.new()
	content_box.custom_minimum_size = Vector2(456, 0)
	content_box.add_theme_constant_override("separation", 8)
	add_child(content_box)

	var header = _panel()
	var header_box = VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 4)
	header.add_child(header_box)

	var title = Label.new()
	title.text = "PokeFactory Mobile"
	title.add_theme_font_size_override("font_size", 26)
	title.modulate = ACCENT
	header_box.add_child(title)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_box.add_child(status_label)

	streak_label = Label.new()
	header_box.add_child(streak_label)
	content_box.add_child(header)

	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	battle_button = _action_button("开始对战")
	battle_button.pressed.connect(func(): battle_requested.emit())
	action_row.add_child(battle_button)
	var reset_button = _action_button("重置挑战")
	reset_button.pressed.connect(func(): reset_requested.emit())
	action_row.add_child(reset_button)
	content_box.add_child(action_row)

	var utility_row = HBoxContainer.new()
	utility_row.add_theme_constant_override("separation", 8)
	var save_button = _action_button("保存")
	save_button.pressed.connect(func(): save_requested.emit())
	utility_row.add_child(save_button)
	var pokedex_button = _action_button("全国图鉴")
	pokedex_button.pressed.connect(func(): pokedex_requested.emit())
	utility_row.add_child(pokedex_button)
	content_box.add_child(utility_row)

	content_box.add_child(_section_title("1. 选择初始宝可梦"))
	picker_hint = Label.new()
	content_box.add_child(picker_hint)
	var starter_row = HBoxContainer.new()
	starter_row.add_theme_constant_override("separation", 6)
	for i in range(3):
		var starter_button = _action_button("候选 %d" % (i + 1))
		starter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		starter_button.pressed.connect(starter_selected.emit.bind(i))
		starter_row.add_child(starter_button)
		starter_buttons.append(starter_button)
	content_box.add_child(starter_row)

	content_box.add_child(_section_title("2. 当前 3 人小队"))
	var team_row = HBoxContainer.new()
	team_row.add_theme_constant_override("separation", 6)
	for _team_index in range(3):
		var team_card = _panel()
		team_card.custom_minimum_size = Vector2(0, 150)
		team_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		team_row.add_child(team_card)
		team_cards.append(team_card)
	content_box.add_child(team_row)

	content_box.add_child(_section_title("3. 胜利后 3 选 1 招募"))
	var recruit_row = HBoxContainer.new()
	recruit_row.add_theme_constant_override("separation", 6)
	for i in range(3):
		var recruit_button = _action_button("待解锁")
		recruit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recruit_button.pressed.connect(recruit_selected.emit.bind(i))
		recruit_row.add_child(recruit_button)
		recruit_buttons.append(recruit_button)
	content_box.add_child(recruit_row)

	content_box.add_child(_section_title("4. 下一场对手预览"))
	var opponent_row = HBoxContainer.new()
	opponent_row.add_theme_constant_override("separation", 6)
	for _opp_index in range(3):
		var opponent_card = _panel()
		opponent_card.custom_minimum_size = Vector2(0, 120)
		opponent_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opponent_row.add_child(opponent_card)
		opponent_cards.append(opponent_card)
	content_box.add_child(opponent_row)

	content_box.add_child(_section_title("5. 工厂战报"))
	var log_panel = _panel()
	log_panel.custom_minimum_size = Vector2(0, 170)
	log_label = RichTextLabel.new()
	log_label.fit_content = true
	log_label.scroll_active = true
	log_panel.add_child(log_label)
	content_box.add_child(log_panel)

func _update_starter_buttons(choices: Array, run_active: bool, pokemon_provider, bst_provider: Callable) -> void:
	for i in range(starter_buttons.size()):
		var button = starter_buttons[i]
		if i < choices.size():
			var data = pokemon_provider.call(choices[i])
			button.text = _format_pokemon_button(data, choices[i], bst_provider)
			button.disabled = run_active
		else:
			button.text = "暂无候选"
			button.disabled = true

func _update_team_cards(team_members: Array, bst_provider: Callable) -> void:
	for i in range(team_cards.size()):
		_clear_container(team_cards[i])
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		team_cards[i].add_child(box)
		if i < team_members.size():
			var member = team_members[i]
			var name = Label.new()
			name.text = "%s Lv.%d" % [member.base.get("name", member.base_id), member.level]
			name.add_theme_font_size_override("font_size", 16)
			box.add_child(name)
			box.add_child(_sprite_for_pokemon(member.base_id, 72))
			var info = Label.new()
			info.text = "属性: %s\nHP: %d/%d\nBST: %d" % ["/".join(member.base.get("types", [])), member.current_hp, member.max_hp, bst_provider.call(member.base)]
			info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(info)
		else:
			var empty = Label.new()
			empty.text = "空位\n获胜后可补强"
			empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(empty)

func _update_recruit_buttons(choices: Array, pokemon_provider, bst_provider: Callable) -> void:
	for i in range(recruit_buttons.size()):
		var button = recruit_buttons[i]
		if i < choices.size():
			var data = pokemon_provider.call(choices[i])
			button.text = _format_pokemon_button(data, choices[i], bst_provider)
			button.disabled = false
		else:
			button.text = "战胜对手后解锁"
			button.disabled = true

func _update_opponent_preview(opponents: Array, bst_provider: Callable) -> void:
	for i in range(opponent_cards.size()):
		_clear_container(opponent_cards[i])
		var box = VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		opponent_cards[i].add_child(box)
		if i < opponents.size():
			var opponent = opponents[i]
			var name = Label.new()
			name.text = "%s Lv.%d" % [opponent.get("name", opponent.get("id", "?")), opponent.get("level", 50)]
			box.add_child(name)
			box.add_child(_sprite_for_pokemon(opponent.get("id", ""), 64))
			var info = Label.new()
			info.text = "%s\nBST %d" % ["/".join(opponent.get("types", [])), bst_provider.call(opponent)]
			box.add_child(info)
		else:
			var waiting = Label.new()
			waiting.text = "等待生成"
			box.add_child(waiting)

func _update_log(lines: Array) -> void:
	log_label.clear()
	for line in lines:
		log_label.append_text("• %s\n" % line)

func _clear_container(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()

func _format_pokemon_button(data: Dictionary, pokemon_id: String, bst_provider: Callable) -> String:
	var name = data.get("name", pokemon_id)
	var types = "/".join(data.get("types", []))
	return "%s\n%s · BST %d" % [name, types, bst_provider.call(data)]

func _panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = ACCENT.darkened(0.35)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _section_title(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = ACCENT
	return label

func _action_button(text: String) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.focus_mode = Control.FOCUS_NONE
	return button

func _sprite_for_pokemon(pokemon_id: String, size: int) -> TextureRect:
	var sprite = TextureRect.new()
	sprite.custom_minimum_size = Vector2(size, size)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var path = "res://assets/sprites/pokemon/%s.png" % pokemon_id
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	return sprite
