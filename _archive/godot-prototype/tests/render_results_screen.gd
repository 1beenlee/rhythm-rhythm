extends SceneTree

func _init() -> void:
	var root_node = root
	root_node.size = Vector2i(960, 640)

	var app = load("res://scenes/app.gd").new()
	root_node.add_child(app)

	# Call _show_award_screen with realistic gameplay stats
	var summary := {
		"stage_name": "Rhythm Kitchen",
		"score": 52400,
		"best": 52400,
		"max_combo": 28,
		"counts": {"Perfect": 26, "Good": 3, "Miss": 1}
	}
	app._show_award_screen(summary, "SUPERB")

	# Wait two frames for redraw
	await process_frame
	await process_frame

	var img = root_node.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://qa-evidence/v03-clean")
	img.save_png("res://qa-evidence/v03-clean/results_screen_check.png")
	print("SAVED: res://qa-evidence/v03-clean/results_screen_check.png")
	quit(0)
