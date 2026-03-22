extends PanelContainer

func _ready() -> void:
	if get_child_count() == 0:
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_bottom", 14)
		add_child(margin)
		var label := Label.new()
		label.name = "Label"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		margin.add_child(label)

func setup(text: String) -> void:
	if get_child_count() == 0:
		_ready()
	var label := get_node("MarginContainer/Label") as Label
	label.text = "• %s" % text
