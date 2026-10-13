# THE ENEMY
# A slime that slowly slides towards the player. Touching it costs a life.
#
# The enemy is an Area2D, not a solid body. That means enemies pass straight
# through each other and through walls. This is on purpose: it keeps them
# from getting stuck, and it means there is only one thing to understand
# here, which is "move towards the player".

extends Area2D


# --- THINGS YOU CAN TUNE IN THE INSPECTOR ---------------------------------

## How fast the slime chases you, in pixels per second.
## The player's speed is 300, so anything above that is unfair (but funny).
@export var speed := randf_range(100, 150)

## Tick this off and the slime will run AWAY from you instead.
@export var run_away_instead := false

## How close the slime gets before it stops closing in, in pixels.
## It is still touching you at this distance, so it still hurts, but it
## stops crawling underneath the mushroom where you cannot see it.
## Set it to 0 and slimes will pile up invisibly on top of you.
@export var keep_distance := 52.0


# --- THINGS THE SCRIPT KEEPS TRACK OF -------------------------------------

var player: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Find the player. Groups are a way of labelling nodes so you can look
	# them up from anywhere. The Player node is in the "player" group.
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	if player == null:
		return

	# An arrow of length 1 pointing from us towards the player.
	var direction := global_position.direction_to(player.global_position)

	if run_away_instead:
		direction = -direction

	# Stop closing in once we're right next to the player, so the slime
	# stays visible at the edge of the mushroom instead of hiding under it.
	var distance := global_position.distance_to(player.global_position)
	if distance > keep_distance or run_away_instead:
		# Move a little bit along that arrow. Multiplying by delta means the
		# slime moves at the same speed no matter how fast the computer is.
		position += direction * speed * delta

	# Face the way we're going.
	if direction.x < 0:
		sprite.flip_h = false
	elif direction.x > 0:
		sprite.flip_h = true

	# Are we touching the player right now? We check every frame rather
	# than only when we first touch, so that sitting on top of the player
	# keeps hurting them once their invincibility flash wears off.
	if overlaps_body(player):
		player.take_hit()
