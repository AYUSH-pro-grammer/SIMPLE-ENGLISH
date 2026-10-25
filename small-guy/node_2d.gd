
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

var target_words: Array[String] = []
var next_index: int = 0
var game_started: bool = false


func _ready() -> void:
	setup_ui()
	randomize()

	start_button.pressed.connect(_on_start_pressed)
	player.jump_started.connect(_on_jump_started)

	start_panel.show()
	game_panel.hide()
	player.hide()

	# Remove any manually created word nodes.
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
		message_label.text = "ERROR: Assign WordButton.tscn in the Inspector!"
		game_started = false
		return

	# Clear the previous round.
	for child in words_container.get_children():
		words_container.remove_child(child)
		child.queue_free()

	# Pick a random sentence.
	var sentence: String = sentences.pick_random()

	target_words.clear()
	for word in sentence.split(" "):
		target_words.append(word)

	next_index = 0

	target_label.text = "TARGET: " + sentence

	var blanks: Array[String] = []
	for word in target_words:
		blanks.append("_")

	answer_label.text = "YOUR ANSWER: " + " ".join(blanks)
	message_label.text = "Find: " + target_words[0]

	# Shuffle the words.
	var shuffled_words = target_words.duplicate()
	shuffled_words.shuffle()

	# Randomly position the word buttons.
	var screen_size = get_viewport_rect().size
	var placed_positions: Array[Vector2] = []

	var left_margin = 70.0
	var right_margin = 70.0
	var top_limit = screen_size.y * 0.45
	var bottom_limit = screen_size.y - 70.0
	var min_distance = 120.0

	for word in shuffled_words:
		var button = word_button_scene.instantiate()

		# Set the word before adding it to the scene.
		button.setup(word)
		words_container.add_child(button)

		var position_found = false
		var button_position = Vector2.ZERO

		for attempt in range(200):
			button_position = Vector2(
				randf_range(left_margin, screen_size.x - right_margin),
				randf_range(top_limit, bottom_limit)
			)

			var valid_position = true

			for existing_position in placed_positions:
				if button_position.distance_to(existing_position) < min_distance:
					valid_position = false
					break

			if valid_position:
				position_found = true
				break

		if not position_found:
			# Fallback for smaller screens.
			button_position = Vector2(
				randf_range(left_margin, screen_size.x - right_margin),
				randf_range(top_limit, bottom_limit)
			)

		button.position = button_position
		placed_positions.append(button_position)

	# Place the player near the bottom center.
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
	var nearest_distance: float = 65.0

	# Find the closest unselected word.
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
		# Correct word!
		nearest_button.mark_selected()
		next_index += 1

		var answer_parts: Array[String] = []

		for i in range(target_words.size()):
			if i < next_index:
				answer_parts.append(target_words[i])
			else:
				answer_parts.append("_")

		answer_label.text = "YOUR ANSWER: " + " ".join(answer_parts)

		if next_index >= target_words.size():
			message_label.text = "Sentence completed!"

			game_started = false
			get_tree().create_timer(1.5).timeout.connect(_next_round)
		else:
			message_label.text = "Find: " + target_words[next_index]

	else:
		# Incorrect word.
		message_label.text = "Wrong word! Find: " + expected_word



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

	$CanvasLayer/StartPanel/StartButton.position = Vector2(150, 200)
	$CanvasLayer/StartPanel/StartButton.size = Vector2(200, 55)

	game_panel.position = Vector2(0, 0)
	game_panel.size = Vector2(screen_size.x, 150)

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
