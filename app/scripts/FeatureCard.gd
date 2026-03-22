extends PanelContainer

const CONTENT_NAME := "Content"
const LABEL_NAME := "Label"

func _ready() -> void:
	_ensure_content()

func setup(text: String) -> void:
	var label := _ensure_content()
	if label:
		label.text = "• %s" % text

func _ensure_content() -> Label:
	var margin := get_node_or_null(CONTENT_NAME) as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = CONTENT_NAME
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_bottom", 14)
		add_child(margin)

	var label := margin.get_node_or_null(LABEL_NAME) as Label
	if label == null:
		label = Label.new()
		label.name = LABEL_NAME
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		margin.add_child(label)

	return label
