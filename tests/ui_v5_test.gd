extends SceneTree
const Main = preload("res://scripts/main_v5.gd")
const Build = preload("res://scripts/build_v5.gd")
var failures=[]
var checks=0
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message); push_error(message)
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	var g=Main.new(); root.add_child(g); await process_frame; g.preview_mode=true
	check(g.state=="bridge","bridge boots")
	for tab in ["出击","军械档案","研究终端","人员通信"]:
		g.bridge_tab=tab; g.show_bridge(); await process_frame
		check(is_instance_valid(g.page),"bridge tab "+tab)
	for kind in ["职业","武器","支援","科技","道具","构筑"]:
		g.archive_kind=kind; g.bridge_tab="军械档案"; g.show_bridge(); await process_frame
		check(is_instance_valid(g.page),"archive "+kind)
	g.debug_preview("shop"); await process_frame
	check(g.state=="shop","shop preview")
	var cash=g.run.cash; var gas=g.run.gas
	g.upgrade_weapon(g.run.weapons[0].uid); await process_frame
	g.close_dialog(); check(g.run.cash==cash,"branch cancel costs zero")
	g.show_research(); await process_frame; g.close_dialog(); check(g.run.gas==gas,"research cancel costs zero")
	g.show_stats(); await process_frame; g.close_dialog()
	g.show_recycle(); await process_frame; g.close_dialog()
	g.show_levels(); await process_frame; g.close_dialog()
	for id in ["W01","W12","S08","T24","I40","B08"]:
		g.detail_dialog(id); await process_frame; g.close_dialog()
	g.show_settings("bridge"); await process_frame
	g.show_layout_editor(); await process_frame
	check(g.control_pos("skill").distance_to(g.control_pos("dash"))>=g.control_radius("skill")+g.control_radius("dash")+12*g.dp_scale(),"control gap")
	g.debug_preview("boss"); await process_frame; g.countdown=0
	check(g.state=="wave" and g.run.wave==12,"boss starts")
	var joy=g.joystick_default(); g.touch_event(1,joy,true); g.drag_event(1,joy+Vector2(30,0))
	g.touch_event(2,g.control_pos("skill"),true); g.touch_event(3,g.control_pos("dash"),true)
	check(g.touch_owners.size()==3,"three fingers owned")
	check(g.move_finger==1 and g.joystick_vector.x>0,"moving finger retained")
	var cooldown=g.sim.skill_cd
	g.drag_event(2,g.cancel_rect().get_center()); g.touch_event(2,g.cancel_rect().get_center(),false)
	check(not g.commands.has("skill") and g.sim.skill_cd==cooldown,"skill cancel no cooldown")
	g.touch_event(3,g.control_pos("dash"),false); check(g.commands.get("dash",false),"dash release casts")
	check(g.move_finger==1,"dash release keeps move")
	g.touch_event(1,joy,false); check(g.joystick_vector==Vector2.ZERO,"move release clears")
	check(g.world_to_screen(g.screen_to_world(Vector2(123,456))).distance_to(Vector2(123,456))<.001,"projection roundtrip")
	g.touch_event(9,g.joystick_default(),true)
	g.pause_game(); await process_frame; check(g.state=="paused","pause state")
	g.touch_event(9,g.joystick_default(),false); g.close_dialog(); g.state="wave"; g.countdown=0
	g.touch_event(10,g.joystick_default(),true); g.drag_event(10,g.joystick_default()+Vector2(30,0))
	check(g.move_finger==10 and g.joystick_vector.x>0,"pause release resume accepts new movement finger")
	g.touch_event(10,g.joystick_default(),false)
	var escape=InputEventKey.new(); escape.keycode=KEY_ESCAPE; escape.pressed=true; g._input(escape)
	check(g.state=="paused","real key event Escape pauses")
	g.close_dialog(); g.state="wave"; g.sim.finished=true; g.finish_result(true); await process_frame
	check(g.state=="result","result page")
	for cid in ["C01","C03","C06"]:
		g.selected_class=cid; g.selected_mode="boss"; g.training_preset=true; g.selected_techs=[]; g.start_new_run()
		check(g.run.weapons.size()==2 and g.run.weapons[0].level==3 and g.run.weapons[1].id=="W05","training preset "+cid)
		check(g.run.supports==["S02"] and g.run.hp==Build.stats(g.run).max_hp,"training start HP and support "+cid)
	g.selected_mode="campaign"; g.start_new_run()
	check(g.run.weapons.size()==1 and g.run.weapons[0].level==1 and g.run.supports.is_empty(),"campaign has no training equipment")
	g.debug_density_scale=2.0; g.settings.large_font=true; g.show_settings("bridge"); await process_frame
	check(g.fs(16)>=42,"130 percent text on 2 UI units per dp")
	check(g.control_radius("skill")*2>=48*g.dp_scale(),"mobile skill at least48dp")
	check(g.control_radius("dash")*2>=48*g.dp_scale(),"mobile dash at least48dp")
	g.settings.left_handed=true; check(g.joystick_default().x>root.get_visible_rect().size.x*.5,"left-handed joystick mirrored")
	print("UI_V5_CHECKS ",checks," FAILURES ",failures)
	g.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
