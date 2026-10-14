# THE GAME
# This is the brain of the whole thing. It keeps the score and the clock,
# spawns slimes and coins, and decides when you have won or lost.
#
# If you want to change WHAT THE GAME ASKS YOU TO DO, you almost certainly
# want the exports below rather than the code. Click the "Main" node in the
# scene tree on the left and look at the Inspector on the right.

extends Node2D


# --- HOW DO YOU WIN? ------------------------------------------------------

## Collect this many points to win. Set it to 0 to turn winning off,
## which turns the game into "survive until the clock runs out".
@export var score_to_win := 8

## How long the round lasts, in seconds.
@export var round_seconds := 45.0

## What happens when the clock hits zero?
## Ticked   = you LOSE when time runs out (a race against the clock).
## Unticked = you WIN when time runs out (a survival game).
@export var lose_when_time_runs_out := true


# --- HOW HARD IS IT? ------------------------------------------------------

## Seconds between slimes appearing. Smaller = more slimes = harder.
@export var seconds_between_spawns := 3.0

## The game stops spawning once there are this many slimes on screen.
@export var max_enemies := 8

## How many slimes are already there when the round starts.
@export var starting_enemies := 2

## How many coins are on screen at once. A new one appears whenever
## you collect one, so this number never changes during play.
@export var coins_on_screen := 4

## Slimes never spawn closer to the player than this, in pixels,
## so you don't get ambushed the instant one appears.
@export var safe_spawn_distance := 250.0


# --- JUICE ----------------------------------------------------------------

## How hard the screen jolts when you get hit, in pixels.
## Set it to 0 for no shake. Above about 30 it becomes hard to play.
@export var shake_strength := 9.0

## How long the jolt lasts, in seconds.
@export var shake_seconds := 0.25


# --- THINGS YOU PROBABLY DON'T NEED TO TOUCH ------------------------------

@export var enemy_scene: PackedScene
@export var pickup_scene: PackedScene


# --- THINGS THE SCRIPT KEEPS TRACK OF -------------------------------------

var score := 0
var time_left := 0.0
var round_over := false
var shake_time_left := 0.0

@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player
@onready var enemies: Node2D = $Enemies
@onready var pickups: Node2D = $Pickups
@onready var hud: CanvasLayer = $HUD
@onready var spawn_timer: Timer = $SpawnTimer


func _ready() -> void:
	time_left = round_seconds

	# Listen to the player so we can update the hearts and end the game.
	player.got_hurt.connect(_on_player_hurt)
	player.died.connect(_on_player_died)

	hud.set_max_lives(player.lives)
	hud.set_lives(player.lives)
	hud.set_score(score, score_to_win)
	hud.set_time(time_left, round_seconds)

	for i in starting_enemies:
		spawn_enemy()

	for i in coins_on_screen:
		spawn_pickup()

	spawn_timer.wait_time = seconds_between_spawns
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()


func _process(delta: float) -> void:
	# Keep shaking even after the round ends, so the final hit still lands.
	update_shake(delta)

	if round_over:
		return

	time_left -= delta
	hud.set_time(time_left, round_seconds)

	if time_left <= 0.0:
		if lose_when_time_runs_out:
			end_round(false, "TIME'S UP")
		else:
			end_round(true, "YOU SURVIVED")


# --- SPAWNING -------------------------------------------------------------
# These functions are deliberately short and public, so that a twist card
# can call them from anywhere with a single line. This node is in the
# "game" group, so any script in the project can reach it like this:
#
#     var game := get_tree().get_first_node_in_group("game")
#     game.spawn_enemy_at(global_position)

## Puts a new slime at an exact spot.
func spawn_enemy_at(where: Vector2) -> void:
	var enemy := enemy_scene.instantiate()
	enemy.position = where
	enemies.add_child(enemy)


## Puts a new coin at an exact spot.
func spawn_pickup_at(where: Vector2) -> void:
	var pickup := pickup_scene.instantiate()
	pickup.position = where
	pickup.collected.connect(_on_pickup_collected)
	pickups.add_child(pickup)


## Puts a new slime somewhere random, but not right on top of the player.
func spawn_enemy() -> void:
	spawn_enemy_at(random_spot_away_from_player())


## Puts a new coin somewhere random, but not right on top of the player.
func spawn_pickup() -> void:
	spawn_pickup_at(random_spot_away_from_player())


# Keeps picking random points until it finds one far enough from the player.
func random_spot_away_from_player() -> Vector2:
	# Stay this far away from the walls so nothing spawns half off-screen.
	var margin := 80.0
	var screen := get_viewport_rect().size

	# Try 30 times. If every try is too close (which can only happen if
	# safe_spawn_distance is enormous) we just use the last one.
	var spot := Vector2.ZERO
	for attempt in 30:
		spot = Vector2(
			randf_range(margin, screen.x - margin),
			randf_range(margin, screen.y - margin)
		)
		if spot.distance_to(player.position) > safe_spawn_distance:
			break

	return spot


func _on_spawn_timer_timeout() -> void:
	if round_over:
		return
	if enemies.get_child_count() < max_enemies:
		spawn_enemy()


# --- SCORE, LIVES AND ENDING ----------------------------------------------

## Adds points to the score and ends the round if that's enough to win.
## Points can be negative. Call this from anywhere, for example:
##     get_tree().get_first_node_in_group("game").add_score(5)
func add_score(points: int) -> void:
	score += points
	hud.set_score(score, score_to_win)

	if score_to_win > 0 and score >= score_to_win:
		end_round(true, "YOU WIN")


func _on_pickup_collected(points: int) -> void:
	$Sounds/PickupSound.play()

	# Replace the coin that was just taken, so the count stays the same.
	spawn_pickup()

	add_score(points)


func _on_player_hurt(lives_left: int) -> void:
	hud.set_lives(lives_left)
	$Sounds/HurtSound.play()
	shake_screen()


func _on_player_died() -> void:
	shake_screen()
	end_round(false, "YOU DIED")


# --- SCREEN SHAKE ---------------------------------------------------------

## Jolts the camera. Call this from anywhere for a bit of impact, e.g.
##     get_parent().shake_screen()
func shake_screen() -> void:
	shake_time_left = shake_seconds


# Nudges the camera to a random spot each frame, less and less as the
# shake wears off, then puts it back exactly where it started.
func update_shake(delta: float) -> void:
	if shake_time_left <= 0.0:
		camera.offset = Vector2.ZERO
		return

	shake_time_left -= delta

	# how_strong goes from 1.0 at the start down to 0.0 at the end
	var how_strong := shake_strength * (shake_time_left / shake_seconds)
	camera.offset = Vector2(
		randf_range(-how_strong, how_strong),
		randf_range(-how_strong, how_strong)
	)


func end_round(did_win: bool, message: String) -> void:
	# Guard against ending twice, for example dying on the same frame
	# that you collect your winning coin.
	if round_over:
		return
	round_over = true

	spawn_timer.stop()

	# Freeze everything that moves, but leave the game running so the
	# end screen can animate and respond to clicks.
	player.is_alive = false
	enemies.process_mode = Node.PROCESS_MODE_DISABLED
	pickups.process_mode = Node.PROCESS_MODE_DISABLED

	if did_win:
		$Sounds/WinSound.play()
	else:
		$Sounds/LoseSound.play()

	hud.show_end_screen(message, score)


func restart() -> void:
	get_tree().reload_current_scene()


func quit_to_title() -> void:
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")


func _unhandled_input(event: InputEvent) -> void:
	# Press R at any time to start the round over.
	if event.is_action_pressed("restart"):
		restart()
