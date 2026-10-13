# A HAZARD
# A blob that sits around for a while and hurts the player.
#
# Nothing in the base game uses this. It exists because several twist cards
# need "a thing that exists for a while and hurts you", and building that
# from scratch is a lot of fiddly typing. Set the exports differently and
# the same scene becomes very different things:
#
#   a puddle of goop   speed 0,   long life,  wide flat scale, green
#   a spit ball        speed 400, short life, small scale,     white
#   an explosion       speed 0,   half a second, huge scale,   orange
#   falling debris     speed 200 pointing down, lives until it leaves
#
# To use one, instance it and drop it into the scene:
#
#   const HAZARD := preload("res://actors/hazard.tscn")
#   var h := HAZARD.instantiate()
#   h.position = global_position
#   h.speed = 400.0
#   h.direction = Vector2.RIGHT
#   get_tree().get_first_node_in_group("game").add_child(h)

extends Area2D


# --- THINGS YOU CAN TUNE IN THE INSPECTOR ---------------------------------

## How fast it travels. Leave at 0 for something that stays put.
@export var speed := 0.0

## Which way it travels. Ignored if speed is 0.
@export var direction := Vector2.ZERO

## How many seconds before it disappears.
@export var lifetime_seconds := 3.0

## Fade away over its lifetime instead of blinking out.
@export var fade_out := true

## Untick this for a harmless decoration.
@export var hurts_player := true

## Delete itself the moment it touches the player, like a bullet does.
@export var vanish_on_hit := false


# --- THINGS THE SCRIPT KEEPS TRACK OF -------------------------------------

var time_left := 0.0
var player: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	time_left = lifetime_seconds
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	position += direction * speed * delta

	time_left -= delta
	if fade_out:
		# Goes from 1.0 when it appears down to 0.0 as it runs out.
		sprite.modulate.a = clampf(time_left / lifetime_seconds, 0.0, 1.0)

	if time_left <= 0.0:
		queue_free()
		return

	if hurts_player and player != null and overlaps_body(player):
		player.take_hit()
		if vanish_on_hit:
			queue_free()
