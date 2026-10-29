extends SceneTree
var errors=0
var checks=0
func _initialize(): call_deferred("run")
func check(value, message):
	checks+=1
	if not value: errors+=1; print("FAIL ",message)
func validate(g):
	await process_frame; await process_frame
	for c in g.overlay.get_children():
		if c is Button:
			check(c.size.y>=56,"touch height "+c.text)
			check(Rect2(Vector2.ZERO,g.SIZE).encloses(c.get_rect()),"button bounds "+c.text)
		if c is RichTextLabel: check(c.get_content_height()<=c.size.y+1,"description overflow "+c.get_parsed_text())
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	g.test_mode=true;g.touch_mode=true;g.start_run();g.paused=true;g.radio.clear_queue()
	g.cash=500; g.finish_wave()
	for id in g.Build.ITEMS:
		g.build.offers=[{"type":"item","id":id,"cost":30}];g.build.locks=[false,false,false,false];g._show_shop();await validate(g)
	for id in g.Build.WEAPON_NAMES:
		g.weapons[0].id=id;g._show_branch(0);await validate(g)
	g._show_menu();await validate(g)
	g._show_bridge();await validate(g)
	print("UI41_LAYOUT checks=",checks," failures=",errors)
	quit(errors)
