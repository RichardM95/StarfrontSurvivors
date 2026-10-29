extends SceneTree
const Main = preload("res://scripts/main.gd")
const Save = preload("res://scripts/save_v2.gd")
var g
var passed := 0
var failed := 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error("FAIL: "+label)
func touch(index: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index=index; e.position=pos; e.pressed=pressed
	g._input(e)
func drag(index: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index=index; e.position=pos
	g._input(e)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	g=Main.new()
	g.test_mode=true
	g.save_path="/tmp/starfront-integration-checkpoint.json"
	Save.clear_run(g.save_path)
	root.add_child(g)
	g.set_process(false)
	for id in g.CLASS_IDS:
		g._show_menu()
		g.selected_class=id
		g.start_run()
		check(g.state=="wave" and g.wave==1 and g.class_id==id,"start "+id)
		check(g.hp==g.max_hp and g.weapons.size()==1,"class stats "+id)
		g.start_wave()
		check(g.wave==1,"duplicate wave start "+id)
		g._update_weapons(0.05)
		check(g.weapons[0].cooldown>=0,"idle weapon cooldown "+id)
		g.finish_wave()
		check(g.state=="shop" and g.build.offers.size()==4,"shop "+id)
		check(Save.validate(g.build),"checkpoint schema "+id)
		var cash_before: int=g.cash
		g.finish_wave()
		check(g.cash==cash_before,"duplicate finish "+id)
	g._show_menu(); g.selected_class="marine"; g.start_run()
	g._gain_xp(15)
	check(g.build.pending_levels==1 and g.state=="wave","queued level during combat")
	g.finish_wave()
	check(g.state=="level" and g.build.level_offers.size()==3,"level overlay")
	var before: int=g.cash
	g._reroll_level()
	check(g.cash==before and g.build.level_rerolls==1,"first reroll free")
	g._choose_level(0)
	check(g.state=="shop" and g.build.pending_levels==0,"choose returns shop")
	g._choose_level(0)
	check(g.build.pending_levels==0,"duplicate choice after shop ignored")
	g.cash=1000
	g.build.offers=[{"type":"weapon","id":"rifle","cost":20},{"type":"weapon","id":"shotgun","cost":20},{"type":"item","id":"pump","cost":20},{}]
	g.build.locks=[false,false,false,false]
	g._lock_offer(1)
	var locked: Dictionary=g.build.offers[1].duplicate(true)
	g._reroll()
	check(g.build.locks[1] and g.build.offers[1]==locked,"lock survives reroll")
	check(g._purchase(1) and g.weapons.size()==2,"buy duplicate-independent slot")
	before=g.cash
	check(not g._purchase(1) and g.cash==before,"sold offer cannot buy twice")
	g.build.offers=[{"type":"upgrade","id":"rifle","uid":g.weapons[0].uid,"from_level":1,"cost":20},{},{},{}]
	check(g._purchase(0) and g.weapons[0].level==2,"specified slot upgrade")
	g.build.offers=[{"type":"upgrade","id":"rifle","uid":g.weapons[0].uid,"from_level":2,"cost":20},{},{},{}]
	check(g._purchase(0) and g.state=="branch","lv3 opens branch")
	check(Save.validate(g.build),"pending branch valid checkpoint")
	g._choose_branch(0,"a")
	check(g.state=="shop" and g.weapons[0].branch=="a","branch choice")
	g._choose_branch(0,"b")
	check(g.weapons[0].branch=="a","branch immutable repeated input")
	g._confirm_sell(1)
	g._sell(1)
	check(g.weapons.size()==1,"confirmed sale")
	g._sell(1)
	check(g.weapons.size()==1,"repeated out-of-range sale harmless")
	g.test_mode=false
	g._persist_checkpoint()
	var saved: Dictionary=Save.load_run(g.save_path)
	check(not saved.is_empty() and saved.weapons[0].branch=="a","checkpoint written")
	var offers_json := JSON.stringify(g.build.offers)
	g._save_and_menu()
	g._resume_run()
	check(g.state=="shop" and g.wave==1 and g.weapons[0].branch=="a","resume complete state")
	check(JSON.stringify(g.build.offers)==offers_json,"resume no offer reroll")
	g.test_mode=true
	g.start_wave()
	check(g.wave==2 and g.state=="wave","resume next wave")
	g.touch_mode=true
	touch(4,Vector2(180,500),true)
	drag(4,Vector2(500,500))
	check(g.joystick_id==4 and g.joystick_vector.x>0.99 and g.joystick_origin.x>180,"floating joystick follows drag")
	touch(5,Vector2(850,500),true)
	drag(5,Vector2(930,500))
	check(g.telemetry.dashes==1,"right swipe dash with left held")
	touch(5,Vector2(930,500),false)
	check(g.joystick_id==4 and g.joystick_vector.x>0,"right release preserves left")
	touch(4,Vector2(500,500),false)
	check(g.joystick_id==-1 and g.joystick_vector==Vector2.ZERO,"left release clears movement")
	touch(8,Vector2(200,500),true); drag(8,Vector2(260,500))
	g._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(g.paused and g.joystick_id==-1 and g.right_touches.is_empty(),"focus loss clears touch and pauses")
	g._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(g.paused,"repeated focus loss remains paused")
	g._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not g.paused,"back resumes paused wave")
	g._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(g.paused,"back pauses active wave")
	# Checkpoint screens retain randomly generated choices and pending branches.
	g._show_menu(); g.start_run()
	g._gain_xp(80)
	g.finish_wave()
	var pending: int=g.build.pending_levels
	var level_json := JSON.stringify(g.build.level_offers)
	g.test_mode=false
	g._persist_checkpoint(); g._show_menu(); g._resume_run()
	check(g.state=="level" and g.build.pending_levels==pending,"resume queued levels")
	check(JSON.stringify(g.build.level_offers)==level_json,"resume exact level cards")
	g.test_mode=true
	var old_button: Button
	for child in g.overlay.get_children():
		if child is Button and child.text=="选择此升级":
			old_button=child
			break
	old_button.pressed.emit()
	var after_one: int=g.build.pending_levels
	old_button.pressed.emit()
	check(after_one==pending-1 and g.build.pending_levels==after_one,"same-frame stale choice button ignored")
	while g.state=="level": g._choose_level(0)
	g.weapons[0].level=3; g.weapons[0].branch=""; g.build.pending_branch=0
	g._advance_checkpoint_ui()
	g.test_mode=false; g._persist_checkpoint(); g._show_menu(); g._resume_run()
	check(g.state=="branch" and g.build.pending_branch==0,"resume pending specialization")
	g.test_mode=true; g._choose_branch(0,"b")
	check(g.state=="shop" and g.weapons[0].branch=="b","resumed specialization selected")
	g.start_wave(); g.start_run()
	check(g.wave==1 and g.state=="wave" and not g.combat.is_empty(),"repeated new run initialization consistent")
	# Canceled touches must clear movement even when paused.
	g.touch_mode=true; touch(9,Vector2(100,500),true); drag(9,Vector2(190,500))
	var canceled := InputEventScreenTouch.new()
	canceled.index=9; canceled.pressed=true; canceled.canceled=true
	g._input(canceled)
	check(g.joystick_id==-1 and g.joystick_vector==Vector2.ZERO,"canceled touch clears joystick")
	Save.clear_run(g.save_path)
	g.queue_free()
	await process_frame
	print("INTEGRATION_V2_TESTS ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
