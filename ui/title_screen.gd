# THE TITLE SCREEN
# This is the first thing people see. It is deliberately almost empty,
# because it is meant to be the easiest place in the project to make the
# game feel like YOURS.
#
# THINGS TO TRY, none of which need any code:
#   * Click "Title" and type your game's name.
#   * Click "Background" and change its Color.
#   * Drop a picture into the "Artwork" slot below to replace the shapes.
#   * Click "Subtitle" and write what the player has to do.

extends Control


## A picture shown in the middle of the title screen.
## Leave it empty and you'll get the placeholder mushroom instead.
@export var artwork: Texture2D

## The scene the Play button loads. You almost certainly want to leave this.
@export var game_scene: PackedScene


@onready var art_slot: TextureRect = $Middle/Artwork


func _ready() -> void:
	if artwork != null:
		art_slot.texture = artwork


func _on_play_pressed() -> void:
	$ClickSound.play()
	get_tree().change_scene_to_packed(game_scene)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	# Any key starts the game, so nobody gets stuck hunting for the mouse.
	if event is InputEventKey and event.pressed:
		_on_play_pressed()
