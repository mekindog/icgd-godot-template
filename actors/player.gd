# THE PLAYER
# This is the mushroom you control with WASD or the arrow keys.
#
# Everything you can safely change is at the top, marked with @export.
# @export means "show this in the Inspector on the right of the screen",
# so you can change it by clicking the Player in the scene and typing a
# new number. You do NOT have to edit this file to change how it feels.

extends CharacterBody2D


# --- THINGS YOU CAN TUNE IN THE INSPECTOR ---------------------------------

## How fast the player moves, in pixels per second.
## Try 100 (slow and heavy) or 700 (very fast).
@export var speed := 300.0

## How many hits the player can take before the game is over.
@export var lives := 3

## After being hit, how many seconds you cannot be hit again.
## During this time the mushroom flashes. Set to 0 for brutal mode.
@export var invincible_seconds := 1.0


# --- SIGNALS --------------------------------------------------------------
# A signal is an announcement. The player shouts "I got hurt!" and the main
# scene listens for it and updates the hearts. Nothing else needs to care.

signal got_hurt(lives_left: int)
signal died


# --- THINGS THE SCRIPT KEEPS TRACK OF -------------------------------------

var is_invincible := false
var is_alive := true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(_delta: float) -> void:
	if not is_alive:
		return

	# 1. Find out which way the player is pressing.
	var direction := get_input_direction()

	# 2. Turn that direction into movement.
	velocity = direction * speed
	move_and_slide()

	# 3. Make the mushroom look like it's doing the right thing.
	update_animation(direction)


# Returns which way the player wants to go, as an arrow of length 1.
# For example: holding D gives (1, 0). Holding W and D gives about (0.7, -0.7).
# If nothing is held it returns (0, 0), which means "stand still".
#
# TWIST CARDS THAT CHANGE MOVEMENT replace the inside of THIS function.
func get_input_direction() -> Vector2:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	# Without this, moving diagonally is faster than moving straight,
	# because you'd be adding two full-speed movements together.
	return direction.normalized()


# Picks the run or idle animation, and faces the way we last moved.
func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		sprite.play("idle")
	else:
		sprite.play("run")

	# Only flip when actually moving left or right, so the mushroom keeps
	# facing the same way while moving straight up or down.
	# The drawing faces LEFT to begin with, so "flipped" means facing right.
	if direction.x < 0:
		sprite.flip_h = false
	elif direction.x > 0:
		sprite.flip_h = true


# Called by an enemy when it touches us.
func take_hit() -> void:
	# Ignore the hit if we're already flashing, or already dead.
	if is_invincible or not is_alive:
		return

	lives -= 1
	got_hurt.emit(lives)

	if lives <= 0:
		is_alive = false
		died.emit()
		return

	start_invincibility()


# Flash the mushroom and ignore hits for a moment.
func start_invincibility() -> void:
	is_invincible = true

	# A tween is an animation made in code. This one fades the mushroom
	# in and out a few times so the player can see they are safe.
	var flash := create_tween()
	flash.set_loops(5)
	flash.tween_property(sprite, "modulate:a", 0.2, invincible_seconds / 10.0)
	flash.tween_property(sprite, "modulate:a", 1.0, invincible_seconds / 10.0)

	await get_tree().create_timer(invincible_seconds).timeout

	is_invincible = false
	sprite.modulate.a = 1.0
