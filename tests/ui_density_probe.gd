extends SceneTree
const Main=preload("res://scripts/main_v5.gd")
func _initialize(): call_deferred("probe")
func walk(node):
	if node is Control and node.visible:
		if node.get_global_rect().end.x>root.get_visible_rect().size.x+1: print("OVERFLOW ",node.get_path()," ",node.get_global_rect()," MIN ",node.get_combined_minimum_size())
	if node is Label and node.get_parent() is HBoxContainer and node.size.x<55 and node.text.length()>4: print("THIN ",node.text," ",node.size)
	for c in node.get_children(): walk(c)
func probe():
	var g=Main.new();root.add_child(g);await process_frame;g.preview_mode=true
	for density in [1.0,2.0]:
		g.debug_density_scale=density; g.settings.large_font=density>1.0
		for page in ["bridge","shop","research","branch","boss","settings"]:
			g.debug_preview(page);await process_frame;await process_frame
			print("PROBE ",density," ",page," viewport ",root.get_visible_rect()," page ",g.page.get_global_rect());walk(g.root_ui)
	g.queue_free();await process_frame;quit()
