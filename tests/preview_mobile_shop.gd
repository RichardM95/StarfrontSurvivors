extends SceneTree
## Visual QA fixture: starts the real supply shop with touch controls enabled.
func _initialize() -> void:
	call_deferred("_show")
func _show() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.test_mode = true
	game.touch_mode = true
	game.start_run()
	game.cash = 100
	game.finish_wave()
