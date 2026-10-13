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

## How fast the coin pulses between bright and dark. Set to 0 to stop it.
@export var pulse_speed := 3.0

## How dark the coin goes at its dimmest.
## 1.0 is no change at all, 0.3 is a strong flicker.
@export var pulse_darkness := 0.55


# --- SIGNALS --------------------------------------------------------------

signal collected(points_scored: int)


# --- THINGS THE SCRIPT KEEPS TRACK OF -------------------------------------

var time_alive := 0.0
var already_collected := false
var player: Node2D = null

@onready var sprite: Polygon2D = $Shape
@onready var burst: CPUParticles2D = $Burst


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	if already_collected:
		return

	time_alive += delta

	# sin() swings smoothly between -1 and 1 forever. The maths below turns
	# that into a brightness between pulse_darkness and 1.0, which we then
	# multiply the coin's colour by. Lower number = darker coin.
	var wave := (sin(time_alive * pulse_speed) + 1.0) / 2.0
	var brightness := lerpf(pulse_darkness, 1.0, wave)
	sprite.modulate = Color(brightness, brightness, brightness)

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
