
extends Area2D

var word: String = ""
var selected: bool = false

const BUTTON_SIZE = Vector2(100, 45)

@onready var label: Label = $Label

func setup(new_word: String) -> void:
	word = new_word

	if is_node_ready():
		label.text = word
		queue_redraw()

func _ready() -> void:
	label.text = word
	label.position = -BUTTON_SIZE / 2.0
	label.size = BUTTON_SIZE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 18)
	queue_redraw()

func _draw() -> void:
	var rect = Rect2(-BUTTON_SIZE / 2.0, BUTTON_SIZE)

	var fill_color = Color("#276749") if selected else Color("#202C42")
	var border_color = Color("#68E0A0") if selected else Color("#78A9FF")

	draw_rect(rect, fill_color, true)
	draw_rect(rect, border_color, false, 3.0)

func mark_selected() -> void:
	selected = true
	queue_redraw()
