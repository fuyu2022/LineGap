extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var destination := args[0] if not args.is_empty() else "res://builds/LineGap-Windows-x64/Godot-Licenses.txt"
	var output := FileAccess.open(destination, FileAccess.WRITE)
	output.store_string("Godot Engine\n\n" + Engine.get_license_text() + "\n\nThird-party copyright information\n\n")
	output.store_string(JSON.stringify(Engine.get_copyright_info(), "\t"))
	output.store_string("\n\nThird-party license texts\n\n")
	var licenses := Engine.get_license_info()
	for name in licenses:
		output.store_string(name + "\n" + str(licenses[name]) + "\n\n")
	output.close()
	print("Engine licenses saved")
	quit()
