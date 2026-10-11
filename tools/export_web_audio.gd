extends SceneTree

const Game = preload("res://scripts/game.gd")

func _initialize() -> void:
	var directory := ProjectSettings.globalize_path("res://builds/LineGap-Web/audio")
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		printerr("Could not create Web audio directory")
		quit(1)
		return
	var game = Game.new()
	var sounds := {
		"collect": game._make_sound(720, 1180, 0.12),
		"hit": game._make_sound(340, 150, 0.1),
		"shatter": game._make_impact_sound(false),
		"death": game._make_impact_sound(true),
	}
	for name in sounds:
		var result: Error = sounds[name].save_to_wav(directory.path_join(name + ".wav"))
		if result != OK:
			printerr("Could not export ", name, ": ", error_string(result))
			game.free()
			quit(1)
			return
	game.free()
	print("Exported four Web sound effects from the game synthesis code")
	quit()
