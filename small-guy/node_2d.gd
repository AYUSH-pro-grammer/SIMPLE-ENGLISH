
extends Node2D

@export var word_button_scene: PackedScene

@onready var player = $Player
@onready var words_container = $Words

@onready var start_panel = $CanvasLayer/StartPanel
@onready var start_button = $CanvasLayer/StartPanel/StartButton
@onready var game_panel = $CanvasLayer/GamePanel

@onready var target_label = $CanvasLayer/GamePanel/TargetLabel
@onready var answer_label = $CanvasLayer/GamePanel/AnswerLabel
@onready var message_label = $CanvasLayer/GamePanel/MessageLabel

const EXTRA_WORD_COUNT = 7
const UI_HEIGHT = 150.0
const BUTTON_MARGIN = 70.0
const MIN_DISTANCE = 120.0

var sentences = [
	"hey how are you",
	"i like this game",
	"the cat is small",
	"we can jump high",
	"godot is very cool",
	"the sun is bright",
	"i love playing games",
	"jump and find words"
]

var extra_words = [
	"dog", "happy", "blue", "bird", "big",
	"small", "tree", "fast", "fish", "sun",
	"apple", "green", "house", "star", "book",
	"moon", "run", "water", "red", "fun"
]

var target_words: Array[String] = []
var next_index: int = 0
var game_started: bool = false


func _ready() -> void:
	randomize()
	setup_ui()

	start_button.pressed.connect(_on_start_pressed)
	player.jump_started.connect(_on_jump_started)

	start_panel.show()
	game_panel.hide()
	player.hide()

	for child in words_container.get_children():
		child.queue_free()


func _on_start_pressed() -> void:
	start_panel.hide()
	game_panel.show()
	player.show()

	game_started = true
	new_round()


func new_round() -> void:
	if word_button_scene == null:
		message_label.text = "Assign WordButton.tscn in Inspector!"
		game_started = false
		return

	for child in words_container.get_children():
		words_container.remove_child(child)
		child.queue_free()

	var sentence: String = sentences.pick_random()

	target_words.clear()
	for word in sentence.split(" "):
		target_words.append(word)

	next_index = 0

	target_label.text = "TARGET: " + sentence
	update_answer()
	message_label.text = "Find: " + target_words[0]

	var all_words: Array[String] = target_words.duplicate()
	var decoys: Array[String] = []

	for word in extra_words:
		if not target_words.has(word):
			decoys.append(word)

	decoys.shuffle()

	for i in range(mini(EXTRA_WORD_COUNT, decoys.size())):
		all_words.append(decoys[i])

	all_words.shuffle()

	var screen_size = get_viewport_rect().size
	var placed_positions: Array[Vector2] = []

	var left = BUTTON_MARGIN
	var right = maxf(left, screen_size.x - BUTTON_MARGIN)
	var top = UI_HEIGHT + 65.0
	var bottom = maxf(top, screen_size.y - BUTTON_MARGIN)

	for word in all_words:
		var button = word_button_scene.instantiate()
		button.setup(word)
		words_container.add_child(button)

		var button_pos = Vector2.ZERO
		var found_position = false

		for attempt in range(200):
			button_pos = Vector2(
				randf_range(left, right),
				randf_range(top, bottom)
			)

			var valid = true
			for existing in placed_positions:
				if button_pos.distance_to(existing) < MIN_DISTANCE:
					valid = false
					break

			if valid:
				found_position = true
				break

		if not found_position:
			button_pos = Vector2(
				randf_range(left, right),
				randf_range(top, bottom)
			)

		button.position = button_pos
		placed_positions.append(button_pos)

	player.position = Vector2(
		screen_size.x / 2.0,
		screen_size.y - 100.0
	)


func _on_jump_started(ground_pos: Vector2) -> void:
	if not game_started:
		return

	if next_index >= target_words.size():
		return

	var nearest_button = null
	var nearest_distance = 65.0

	for button in words_container.get_children():
		if button.selected:
			continue

		var distance = ground_pos.distance_to(button.global_position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_button = button

	if nearest_button == null:
		message_label.text = "Get closer to a word!"
		return

	var expected_word = target_words[next_index]

	if nearest_button.word == expected_word:
		nearest_button.mark_selected()
		next_index += 1
		update_answer()

		if next_index >= target_words.size():
			message_label.text = "Sentence completed!"

			game_started = false
			get_tree().create_timer(1.5).timeout.connect(_next_round)
		else:
			message_label.text = "Find: " + target_words[next_index]
	else:
		message_label.text = "Wrong word! Find: " + expected_word


func update_answer() -> void:
	var answer_parts: Array[String] = []

	for i in range(target_words.size()):
		if i < next_index:
			answer_parts.append(target_words[i])
		else:
			answer_parts.append("_")

	answer_label.text = "YOUR ANSWER: " + " ".join(answer_parts)


func setup_ui() -> void:
	var screen_size = get_viewport_rect().size

	start_panel.position = Vector2(
		(screen_size.x - 500.0) / 2.0,
		(screen_size.y - 300.0) / 2.0
	)
	start_panel.size = Vector2(500, 300)

	$CanvasLayer/StartPanel/TitleLabel.position = Vector2(50, 35)
	$CanvasLayer/StartPanel/TitleLabel.size = Vector2(400, 70)

	$CanvasLayer/StartPanel/SubtitleLabel.position = Vector2(30, 115)
	$CanvasLayer/StartPanel/SubtitleLabel.size = Vector2(440, 45)

	start_button.position = Vector2(150, 200)
	start_button.size = Vector2(200, 55)

	game_panel.position = Vector2.ZERO
	game_panel.size = Vector2(screen_size.x, UI_HEIGHT)

	target_label.position = Vector2(30, 15)
	target_label.size = Vector2(screen_size.x - 60, 40)

	answer_label.position = Vector2(30, 60)
	answer_label.size = Vector2(screen_size.x - 60, 35)

	message_label.position = Vector2(30, 100)
	message_label.size = Vector2(screen_size.x - 60, 35)


func _next_round() -> void:
	if not is_inside_tree():
		return

	new_round()
	game_started = true
