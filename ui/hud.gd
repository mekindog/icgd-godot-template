# THE HUD (Heads-Up Display)
# The score, the hearts, the clock bar, and the end screen.
#
# This script does not decide anything about the game. It is only told
# what to show by main.gd. If you want to change the RULES, edit main.gd.
# If you want to change how things LOOK, edit hud.tscn or the exports here.

extends CanvasLayer


# --- THINGS YOU CAN TUNE IN THE INSPECTOR ---------------------------------

## The picture used for each life. Drop a different image here to change it.
@export var heart_texture: Texture2D

## How big each heart is, in pixels.
@export var heart_size := Vector2(44, 40)


@onready var hearts: HBoxContainer = $Hearts
@onready var score_label: Label = $ScoreLabel
@onready var timer_bar: ProgressBar = $TimerBar
@onready var end_screen: Control = $EndScreen
@onready var end_message: Label = $EndScreen/Panel/Lines/Message
@onready var end_score: Label = $EndScreen/Panel/Lines/FinalScore


func _ready() -> void:
	end_screen.hide()


# Builds the row of hearts. Called once at the start of the round.
func set_max_lives(how_many: int) -> void:
	# Clear out any hearts that are already there.
	for old_heart in hearts.get_children():
		old_heart.queue_free()

	for i in how_many:
		var heart := TextureRect.new()
		heart.texture = heart_texture
		heart.custom_minimum_size = heart_size
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts.add_child(heart)


# Dims the hearts the player has lost, rather than removing them, so the
# row doesn't jump around and you can still see how many you started with.
func set_lives(lives_left: int) -> void:
	for i in hearts.get_child_count():
		var heart: TextureRect = hearts.get_child(i)
		if i < lives_left:
			heart.modulate = Color(1, 1, 1, 1)
		else:
			heart.modulate = Color(0, 0, 0, 0.35)


func set_score(score: int, score_to_win: int) -> void:
	if score_to_win > 0:
		score_label.text = "%d / %d" % [score, score_to_win]
	else:
		score_label.text = str(score)


func set_time(time_left: float, round_seconds: float) -> void:
	# The bar empties as the round goes on. We use max(0, ...) so it never
	# goes below empty if the clock dips slightly past zero.
	timer_bar.value = max(0.0, time_left) / round_seconds * 100.0


func show_end_screen(message: String, final_score: int) -> void:
	end_message.text = message
	end_score.text = "Score: %d" % final_score
	end_screen.show()


# --- BUTTONS --------------------------------------------------------------
# These are hooked up to the buttons in hud.tscn.

func _on_restart_pressed() -> void:
	$Sounds/ClickSound.play()
	get_parent().restart()


func _on_title_pressed() -> void:
	$Sounds/ClickSound.play()
	get_parent().quit_to_title()
