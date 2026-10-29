extends SceneTree
func _initialize():
 var game=load("res://scripts/main_v5.gd").new()
 game.debug_density_scale=1.0 # Headless display has zero physical screen pixels; substitute an explicit screen scale.
 root.add_child.call_deferred(game)
 create_timer(0.2).timeout.connect(func(): print("EXPORTED_MOBILE_RESOURCE_SMOKE_OK");quit())
