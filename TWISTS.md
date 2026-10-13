# TWIST CARDS

Every card here has a snippet that works against this project as it stands.
Find your card, open the file it names, and paste.

**Dots are effort, not quality.** ●○○ is ten minutes. ●●● is most of your
session. A one-dot game that is finished and tested beats a three-dot game
that crashes in the gallery.

**Some snippets have a `# YOUR BIT:` comment.** That is the part nobody can
write for you. The plumbing is done; the decision is yours.

---

## Things the base game already gives you

You can reach the main game script from absolutely anywhere:

```gdscript
var game := get_tree().get_first_node_in_group("game")
```

And then call any of these:

| Call | What it does |
|---|---|
| `game.add_score(5)` | Adds points, ends the round if that wins it. Negative works. |
| `game.spawn_enemy_at(pos)` | New slime at an exact spot. |
| `game.spawn_pickup_at(pos)` | New coin at an exact spot. |
| `game.spawn_enemy()` | New slime somewhere random and fair. |
| `game.spawn_pickup()` | New coin somewhere random and fair. |
| `game.shake_screen()` | Jolt the camera. |

There is also **`actors/hazard.tscn`** — a blob that exists for a while and
hurts the player. Nothing uses it by default. Set its exports differently and
it becomes goop, a bullet, an explosion or falling debris. Several cards
below use it.

---

# CODING #1 — YOU

## Comet ●●●
> You don't walk. You launch, and you don't stop until you hit a wall.

**File: `actors/player.gd`.** Add this variable under the others:

```gdscript
var launch_direction := Vector2.ZERO
```

Then replace the whole of `_physics_process` with this:

```gdscript
func _physics_process(_delta: float) -> void:
	if not is_alive:
		return

	# We only listen to the keys while we are standing still.
	# Once we're moving, the input is ignored until we stop.
	if launch_direction == Vector2.ZERO:
		launch_direction = get_input_direction()

	velocity = launch_direction * speed
	move_and_slide()

	# Did we hit a wall this frame?
	if is_on_wall():
		# YOUR BIT: what happens when a comet hits a wall?
		#   launch_direction = Vector2.ZERO          # stop dead
		#   launch_direction = -launch_direction     # bounce straight back
		#   take_hit()                               # ouch
		launch_direction = Vector2.ZERO

	update_animation(launch_direction)
```

**Also:** click the Player and turn **Speed** up to about **900**. At 300 this
feels like wading, not launching.

---

## Black Hole ●●○
> The middle of the room is hungry, and you have no brakes.

**File: `actors/player.gd`.** Add these two near the other `@export` lines at
the top:

```gdscript
## How hard the centre of the screen drags you towards it.
@export var pull_strength := 900.0

## How quickly you lose speed. Lower = more slippery.
@export var drag := 1.5
```

Then replace the whole of `_physics_process` with this:

```gdscript
func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	var direction := get_input_direction()

	# Your own thrust. Notice we ADD to velocity instead of setting it,
	# which is what gives you momentum instead of instant stops.
	velocity += direction * speed * delta * 6.0

	# The pull of the middle of the screen.
	var centre := get_viewport_rect().size / 2.0
	velocity += global_position.direction_to(centre) * pull_strength * delta

	# Drag, so you don't build up speed forever.
	velocity = velocity.lerp(Vector2.ZERO, drag * delta)

	move_and_slide()
	update_animation(direction)
```

**Try this:** set `drag` to `0.3` and you get a proper slingshot — you can
whip around the centre and fling yourself at a coin.

---

## Dizzy ●●○
> Every few seconds your legs stop listening.

**File: `actors/player.gd`.** Add these at the top with the other exports:

```gdscript
## Seconds of normal walking between dizzy spells.
@export var seconds_between_spells := 4.0

## How long each dizzy spell lasts.
@export var spell_seconds := 1.2

var spell_countdown := 0.0
var spell_left := 0.0
var stagger := Vector2.ZERO
```

Then replace the whole of `_physics_process` with this:

```gdscript
func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Count down to the next spell.
	spell_countdown -= delta
	if spell_countdown <= 0.0:
		spell_countdown = seconds_between_spells
		spell_left = spell_seconds
		# A random direction to stagger off in, picked once per spell.
		stagger = Vector2.RIGHT.rotated(randf() * TAU)

	var direction := get_input_direction()

	if spell_left > 0.0:
		spell_left -= delta
		sprite.modulate = Color(0.6, 0.8, 1.0, sprite.modulate.a)

		# YOUR BIT: what does "your legs stop listening" mean?
		#   direction = Vector2.ZERO    # frozen to the spot
		#   direction = -direction      # controls reversed
		#   direction = stagger         # wanders off on its own
		direction = stagger
	else:
		sprite.modulate = Color(1, 1, 1, sprite.modulate.a)

	velocity = direction * speed
	move_and_slide()
	update_animation(direction)
```

---

## Swell ●●○
> Every coin makes you bigger. Bigger is not better.

This one needs **two small pastes in two files.**

**File 1: `actors/player.gd`.** Add at the top with the other exports:

```gdscript
## How much bigger you get per coin. 0.12 is a 12% jump each time.
@export var growth_per_coin := 0.12

## How much speed you lose per coin.
@export var slowdown_per_coin := 18.0
```

And add this as a new function at the bottom of the file:

```gdscript
# Called by main.gd every time a coin is collected.
func on_coin_collected() -> void:
	scale += Vector2(growth_per_coin, growth_per_coin)
	# Never let the player get so slow the game is unplayable.
	speed = maxf(60.0, speed - slowdown_per_coin)
```

**File 2: `main.gd`.** Find `_on_pickup_collected` and add one line:

```gdscript
func _on_pickup_collected(points: int) -> void:
	$Sounds/PickupSound.play()
	spawn_pickup()
	player.on_coin_collected()          # <-- add this line
	add_score(points)
```

**Worth knowing:** scaling the Player scales its collision circle too, so you
really do get easier to hit. That's the whole card.

---

## Twins ●●●
> You are two mushrooms at once. They move in mirror. Both must live.

**The heaviest card in the deck.** Four small pastes, because the base game
assumes there is exactly one player and you are about to break that.

**1. `actors/player.gd`** — add at the top:

```gdscript
## Tick this on the second mushroom so it mirrors the first.
@export var mirror_input := false
```

and inside `get_input_direction`, just before the `return` line:

```gdscript
	if mirror_input:
		direction.x = -direction.x
```

**2. The scene** — open `main.tscn`, click the Player node, press
**Ctrl+D** to duplicate it. Drag the copy to the other side of the arena,
and in the Inspector tick **Mirror Input**. Check it is still in the
`player` group (Node tab → Groups).

**3. `actors/enemy.gd`** — slimes currently find one player and remember it
forever. Make them chase whichever is closer. Add this function:

```gdscript
func nearest_player() -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for p in get_tree().get_nodes_in_group("player"):
		var d: float = global_position.distance_to(p.global_position)
		if d < best_distance:
			best_distance = d
			best = p
	return best
```

and at the very top of `_process`, add:

```gdscript
	player = nearest_player()
```

**4. `actors/pickup.gd`** — let either mushroom pick coins up. Replace the
last two lines of `_process` with:

```gdscript
	for p in get_tree().get_nodes_in_group("player"):
		if overlaps_body(p):
			collect()
			break
```

**5. `main.gd`** — so that either death ends the round. In `_ready`, after
the existing `player.died.connect(...)` line:

```gdscript
	$Player2.got_hurt.connect(_on_player_hurt)
	$Player2.died.connect(_on_player_died)
```

(Use whatever you named the duplicate.) The hearts in the corner will track
whichever mushroom was hit last — fixing that properly is a bonus task.

---

# CODING #2 — THE WORLD

## Gilded ●●○
> One slime in five is solid gold. That one pays.

**File: `actors/enemy.gd`.** Add at the top:

```gdscript
## Chance a slime is gold, from 0.0 (never) to 1.0 (always).
@export var gold_chance := 0.2

## Points a gold slime pays out when you touch it.
@export var gold_points := 3

var is_gold := false
```

In `_ready`, add:

```gdscript
	if randf() < gold_chance:
		is_gold = true
		# Values above 1 make it glow rather than just tint.
		sprite.modulate = Color(1.6, 1.3, 0.3)
```

Then replace the last two lines of `_process` with:

```gdscript
	if overlaps_body(player):
		if is_gold:
			get_tree().get_first_node_in_group("game").add_score(gold_points)
			queue_free()
		else:
			player.take_hit()
```

---

## Mutants ●●○
> Some slimes turn red, charge like hell, and burn out in seconds.

**File: `actors/enemy.gd`.** Add at the top:

```gdscript
## Chance a slime is born as a mutant.
@export var mutant_chance := 0.25

## How many times faster a mutant is.
@export var mutant_speed_multiplier := 3.5

## How long a mutant lives before it burns out.
@export var mutant_seconds := 4.0
```

Then add this at the **end** of `_ready` (it must be last, because the
`await` pauses the rest of the function):

```gdscript
	if randf() < mutant_chance:
		speed *= mutant_speed_multiplier
		keep_distance = 30.0
		sprite.modulate = Color(1.8, 0.4, 0.4)

		# Wait, then die of exhaustion.
		await get_tree().create_timer(mutant_seconds).timeout
		queue_free()
```

**Try this:** give mutants a wind-up — tint them red, wait half a second,
*then* let them charge. A warning makes it feel fair instead of cheap.

---

## Spitters ●●●
> Some slimes stop, take aim, and spit.

**File: `actors/enemy.gd`.** Add at the very top, under `extends Area2D`:

```gdscript
const HAZARD := preload("res://actors/hazard.tscn")
```

With the other exports:

```gdscript
## Chance a slime is a spitter.
@export var spitter_chance := 0.35

## Seconds between shots.
@export var seconds_between_spits := 2.0

## How fast the spit travels.
@export var spit_speed := 450.0

var is_spitter := false
var spit_countdown := 0.0
```

In `_ready`:

```gdscript
	if randf() < spitter_chance:
		is_spitter = true
		sprite.modulate = Color(0.7, 0.5, 1.4)
		# Hang back at a distance and shoot instead of closing in.
		keep_distance = 320.0
```

At the end of `_process`:

```gdscript
	if is_spitter:
		spit_countdown -= delta
		if spit_countdown <= 0.0:
			spit_countdown = seconds_between_spits
			spit()
```

And a new function at the bottom:

```gdscript
func spit() -> void:
	var ball := HAZARD.instantiate()
	ball.position = global_position
	ball.direction = global_position.direction_to(player.global_position)
	ball.speed = spit_speed
	ball.lifetime_seconds = 3.0
	ball.fade_out = false
	ball.vanish_on_hit = true
	ball.scale = Vector2(0.5, 0.5)

	# Added to the game itself, so it draws on top and is easy to see.
	get_tree().get_first_node_in_group("game").add_child(ball)
```

**Important:** set the properties *before* `add_child`. The hazard reads them
the moment it enters the scene, so anything you set afterwards is ignored.

---

## Blight ●●○
> Coins rot. Leave one too long and it stands up and chases you.

**File: `actors/pickup.gd`.** Add at the top with the other exports:

```gdscript
## Seconds before an untouched coin turns into a slime.
@export var seconds_before_rotting := 6.0
```

Inside `_process`, just after the `time_alive += delta` line:

```gdscript
	# YOUR BIT: give the player a warning. Try tinting the coin greener
	# as it ages, so people can see which one is about to turn.
	if time_alive > seconds_before_rotting:
		rot()
		return
```

And a new function at the bottom:

```gdscript
func rot() -> void:
	already_collected = true      # stops this running twice

	var game := get_tree().get_first_node_in_group("game")
	game.spawn_enemy_at(position)
	game.spawn_pickup()           # keep the number of coins the same

	queue_free()
```

---

## Goop ●●○
> Slimes leave a trail behind them. The trail still hurts.

**File: `actors/enemy.gd`.** Add under `extends Area2D`:

```gdscript
const HAZARD := preload("res://actors/hazard.tscn")
```

With the other exports:

```gdscript
## Seconds between blobs of goop.
@export var seconds_between_drips := 0.35

## How long each blob lasts before it dries up.
@export var goop_seconds := 4.0

var drip_countdown := 0.0
```

At the end of `_process`:

```gdscript
	drip_countdown -= delta
	if drip_countdown <= 0.0:
		drip_countdown = seconds_between_drips
		drop_goop()
```

And a new function at the bottom:

```gdscript
func drop_goop() -> void:
	var goop := HAZARD.instantiate()
	goop.position = global_position + Vector2(0, 20)
	goop.lifetime_seconds = goop_seconds
	goop.scale = Vector2(1.2, 0.6)

	# Added to the Pickups container rather than the game itself, because
	# everything in there is drawn UNDER the mushroom. Goop on top of your
	# own character is impossible to see past.
	var game := get_tree().get_first_node_in_group("game")
	game.get_node("Pickups").add_child(goop)
```

**Watch out:** at 0.35 seconds a slime lays a lot of goop. Start there, then
tune `seconds_between_drips` and `goop_seconds` until the arena is dangerous
but not a solid carpet.

---

# CHALLENGE — OPTIONAL

**Before you start one of these, copy your whole project folder somewhere
safe.** You don't have undo across files, and "we broke it and can't get
back" is the only way to end up with nothing to show.

## Flipside ●●●
> Every few seconds the world becomes somewhere else. Learn both.

Three files. Do them in this order and test after each one.

**1. `main.gd`** — add at the top:

```gdscript
## Seconds of normal world between flips.
@export var seconds_between_flips := 8.0

## How long you spend on the other side.
@export var flip_seconds := 4.0

var is_flipped := false
var flip_countdown := 0.0
```

and inside `_process`, just after `update_shake(delta)`:

```gdscript
	flip_countdown -= delta
	if flip_countdown <= 0.0:
		is_flipped = not is_flipped
		flip_countdown = flip_seconds if is_flipped else seconds_between_flips
		shake_screen()

		# YOUR BIT: make the other side LOOK like somewhere else.
		if is_flipped:
			$Background.color = Color(0.35, 0.05, 0.1)
		else:
			$Background.color = Color(0.13, 0.15, 0.2)
```

**2. `actors/enemy.gd`** — at the top of `_process`, after the
`if player == null` check:

```gdscript
	var game := get_tree().get_first_node_in_group("game")
	if game.is_flipped:
		# YOUR BIT: what are the slimes like on the other side?
		speed = 420.0
	else:
		speed = 110.0
```

**3. `actors/player.gd`** — at the very top of `take_hit`:

```gdscript
	# On the other side, you are safe as long as you keep perfectly still.
	var game := get_tree().get_first_node_in_group("game")
	if game.is_flipped and velocity.length() < 1.0:
		return
```

That last paste is what turns this from a visual effect into a game. Standing
still stops being the thing you do when you're confused and starts being the
thing that saves you.

---

## Bombs ●●○
> Put something explosive in the arena. You decide who it hurts.

**File: `main.gd`.** Add under `extends Node2D`:

```gdscript
const HAZARD := preload("res://actors/hazard.tscn")
```

With the other exports:

```gdscript
## Seconds between bombs.
@export var seconds_between_bombs := 5.0

var bomb_countdown := 0.0
```

Inside `_process`, after `update_shake(delta)`:

```gdscript
	bomb_countdown -= delta
	if bomb_countdown <= 0.0:
		bomb_countdown = seconds_between_bombs
		drop_bomb(random_spot_away_from_player())
```

And a new function:

```gdscript
func drop_bomb(where: Vector2) -> void:
	# The warning. Harmless, just sits there looking ominous.
	var warning := HAZARD.instantiate()
	warning.position = where
	warning.lifetime_seconds = 2.0
	warning.hurts_player = false
	warning.scale = Vector2(3, 3)
	warning.get_node("Sprite2D").modulate = Color(1, 0.4, 0.2, 0.5)
	add_child(warning)

	await get_tree().create_timer(2.0).timeout

	# The blast.
	var blast := HAZARD.instantiate()
	blast.position = where
	blast.lifetime_seconds = 0.5
	blast.scale = Vector2(4, 4)
	blast.get_node("Sprite2D").modulate = Color(1, 0.85, 0.3)
	add_child(blast)
	shake_screen()

	# YOUR BIT: should the blast kill slimes too? Loop over
	# enemies.get_children() and free the ones close to "where".
```

---

## Downpour ●●○
> Something falls from the sky. It is not on your side.

**File: `main.gd`.** Add under `extends Node2D`:

```gdscript
const HAZARD := preload("res://actors/hazard.tscn")
```

With the other exports:

```gdscript
## Seconds between falling things. Smaller = heavier rain.
@export var seconds_between_drops := 0.6

## How fast they fall.
@export var drop_speed := 320.0

var drop_countdown := 0.0
```

Inside `_process`, after `update_shake(delta)`:

```gdscript
	drop_countdown -= delta
	if drop_countdown <= 0.0:
		drop_countdown = seconds_between_drops

		var thing := HAZARD.instantiate()
		# Start just above the top of the screen, at a random x.
		thing.position = Vector2(randf_range(40, 1112), -40)
		thing.direction = Vector2.DOWN
		thing.speed = drop_speed
		thing.lifetime_seconds = 4.0
		thing.fade_out = false
		add_child(thing)
```

**YOUR BIT:** re-theme it. Meteors, hail, anvils, cupcakes, fillings. Change
the Sprite2D's texture inside `hazard.tscn` and it changes everywhere.

---

## Player 2 ●●●
> A second player, same keyboard.

The keys are already set up for you: **IJKL** is bound to `p2_up`,
`p2_left`, `p2_down`, `p2_right` in Project Settings.

**1. `actors/player.gd`** — add at the top:

```gdscript
## Tick this on the second mushroom to use IJKL instead of WASD.
@export var use_player_2_keys := false
```

and replace the two `direction` lines inside `get_input_direction`:

```gdscript
	if use_player_2_keys:
		direction.x = Input.get_axis("p2_left", "p2_right")
		direction.y = Input.get_axis("p2_up", "p2_down")
	else:
		direction.x = Input.get_axis("move_left", "move_right")
		direction.y = Input.get_axis("move_up", "move_down")
```

**2.** Duplicate the Player node in `main.tscn` with **Ctrl+D**, move it, and
tick **Use Player 2 Keys**.

**3.** Then do **steps 3, 4 and 5 of the Twins card above** — nearest-player
chasing, both-players coin pickup, and connecting the second player's
signals. Those steps are about having two players at all, not about
mirroring, so they apply here identically.

**YOUR BIT:** is this co-op or competitive? Shared score and shared lives, or
one each and highest wins?

---

## Endless ●○○
> No clock, no target. It just gets worse forever.

**File: `main.gd`.** Add with the other exports:

```gdscript
## Seconds between difficulty steps.
@export var seconds_per_difficulty_step := 10.0

var difficulty_countdown := 0.0
```

At the end of `_ready`:

```gdscript
	# Switch off winning and switch off the clock.
	score_to_win = 0
	lose_when_time_runs_out = false
	round_seconds = 99999.0
	time_left = round_seconds
	hud.get_node("TimerBar").hide()
```

Inside `_process`, after `update_shake(delta)`:

```gdscript
	difficulty_countdown -= delta
	if difficulty_countdown <= 0.0:
		difficulty_countdown = seconds_per_difficulty_step

		# YOUR BIT: what gets worse? More slimes? Faster ones?
		# Fewer coins? All three?
		max_enemies += 2
		seconds_between_spawns = maxf(0.4, seconds_between_spawns - 0.3)
		spawn_timer.wait_time = seconds_between_spawns
```

The only way out is dying, so the score on the end screen becomes the whole
point. Tell people their number.

---

# THEME

Your theme word changes **art, sound and names only**. No code.

You must change **at least two things** to match it. Obvious candidates:
the background colour, the player sprite, the coin shape and colour, the
four sound effects, the title and subtitle on the title screen, the heart
icon, the particle colours.

| Card | Words |
|---|---|
| 1 | Bakery · Dentist |
| 2 | Deep Sea · Graveyard |
| 3 | Haunted · Swamp |
| 4 | Arctic · Junk |
| 5 | Factory · Sweets |

More sprites in the same style as the mushroom and the slimes are linked in
`CREDITS.txt`.

---

# BEFORE YOU DEMO

Set your own win condition on the **Main** node — `Score To Win`,
`Round Seconds`, `Lose When Time Runs Out` — and then **beat your own game
three times.** If you can't, it's too hard. If you can't lose, it's too easy.

Name it on the title screen. An unnamed game looks unfinished even when it
isn't.
