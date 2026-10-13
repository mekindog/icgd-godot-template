# THE PICKUP
# A glowing coin. Walk into it to score points.
#
# When collected it does three things: adds to the score, fires off a little
# burst of particles, and then deletes itself. The main scene immediately
# spawns a replacement somewhere else, so you never run out.

extends Area2D


# --- THINGS YOU CAN TUNE IN THE INSPECTOR ---------------------------------

## How many points this pickup is worth.
## Make it negative for a trap that costs you points.
@export var points := 1

## How fast the coin bobs up and down. Set to 0 to make it sit still.
@export var bob_speed := 3.0

## How far the coin bobs up and down, in pixels.
@export var bob_height := 6.0


# --- SIGNALS --------------------------------------------------------------

signal collected(points_scored: int)


# --- THINGS THE SCRIPT KEEPS TRACK OF -------------------------------------

var time_alive := 0.0
var starting_y := 0.0
var already_collected := false
var player: Node2D = null

@onready var sprite: Polygon2D = $Shape
@onready var burst: CPUParticles2D = $Burst


func _ready() -> void:
	starting_y = position.y
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	if already_collected:
		return

	# Make the coin bob gently so it draws the eye.
	# sin() goes smoothly up and down between -1 and 1 forever.
	time_alive += delta
	position.y = starting_y + sin(time_alive * bob_speed) * bob_height

	if player != null and overlaps_body(player):
		collect()


func collect() -> void:
	already_collected = true

	collected.emit(points)

	# Hide the coin but keep the node alive for a moment so the particle
	# burst has time to finish playing. If we deleted it straight away the
	# particles would vanish with it.
	sprite.hide()
	burst.emitting = true

	await get_tree().create_timer(1.0).timeout
	queue_free()
