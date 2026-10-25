
extends CharacterBody2D

signal jump_started(ground_position: Vector2)

const SPEED: float = 250.0
const JUMP_HEIGHT: float = 55.0
const JUMP_DURATION: float = 0.3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_jumping: bool = false
var jump_time: float = 0.0
var ground_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	animated_sprite.stop()
	animated_sprite.frame = 0


func _physics_process(delta: float) -> void:

	if is_jumping:
		jump_time += delta

		var progress: float = minf(
			jump_time / JUMP_DURATION,
			1.0
		)

		global_position = ground_position + Vector2(
			0,
			-sin(progress * PI) * JUMP_HEIGHT
		)

		if progress >= 1.0:
			global_position = ground_position
			is_jumping = false
			velocity = Vector2.ZERO
			animated_sprite.stop()
			animated_sprite.play("run")
			animated_sprite.stop()
			animated_sprite.frame = 0

		return


	var direction: Vector2 = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	velocity = direction * SPEED
	move_and_slide()

	if direction.x < 0:
		animated_sprite.flip_h = true
	elif direction.x > 0:
		animated_sprite.flip_h = false


	if direction != Vector2.ZERO:
		if animated_sprite.animation != "run" or not animated_sprite.is_playing():
			animated_sprite.play("run")
	else:
		animated_sprite.stop()
		if animated_sprite.animation != "run":
			animated_sprite.animation = "run"
		animated_sprite.frame = 0

	if Input.is_action_just_pressed("jump"):
		ground_position = global_position
		jump_time = 0.0
		is_jumping = true
		velocity = Vector2.ZERO

		animated_sprite.play("jump")

		jump_started.emit(ground_position)
