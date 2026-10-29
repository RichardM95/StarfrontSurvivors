extends SceneTree
const Main=preload("res://scripts/main_v5.gd")
const Save=preload("res://scripts/save_v5.gd")
const Build=preload("res://scripts/build_v5.gd")
var checks=0
var failures=[]
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("test")
func test():
 Save.clear_run()
 var g=Main.new();root.add_child(g);await process_frame;g.set_process(false)
 g.selected_class="C06";g.selected_mode="campaign";g.start_new_run();g.set_process(false)
 check(not g.preview_mode,"actual persistence mode")
 check(g.state=="wave" and Save.load_run().ok,"start actual wave writes checkpoint")
 check(g.run.weapons.size()==1 and g.run.weapons[0].level==1 and g.run.supports.is_empty(),"campaign excludes training gear")
 var snapshot=Save.load_run().run.duplicate(true)
 g.touch_event(1,g.joystick_default(),true)
 var key=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true;g._input(key)
 check(g.state=="paused" and g.move_finger==-999,"real key route pauses and clears touch")
 g.show_bridge();g.load_result=Save.load_run();g.continue_run();g.set_process(false)
 check(g.state=="wave" and g.run.hp==snapshot.hp and g.run.rng_state==snapshot.rng_state,"continue restores exact wave start")
 g.sim.active_value=0;g.wave_finished()
 check(g.state=="shop" and g.run.cash==67 and g.run.pending_levels==1,"actual UI wave finish settlement")
 check(Save.load_run().run.shop==g.run.shop,"actual UI settlement saved offers")
 var before=g.run.cash
 g.depart()
 check(g.state=="shop" and g.run.cash==before and g.run.wave==1,"required level blocks departure")
 g.close_dialog();g.transaction(Build.upgrade(g.run,1))
 check(g.run.weapons[0].level==2 and Save.load_run().run.weapons[0].level==2,"actual UI purchase saved")
 var cash=g.run.cash
 g.upgrade_weapon(1);g.close_dialog()
 check(g.run.cash==cash and Save.load_run().run.cash==cash,"cancel branch modal no payment")
 g.transaction(Build.choose_level(g.run,g.run.level_choices[0]));g.depart();g.set_process(false)
 check(g.state=="wave" and g.run.wave==2 and Save.load_run().run.wave==2,"next wave persist completed")
 g.run.hp=0;g.finish_result(false)
 check(g.saved_ok and Save.load_run().run.phase=="result","actual result serializable")
 g.load_result=Save.load_run();g.continue_run()
 check(g.state=="result","result continue does not restart combat")
 g.queue_free();await process_frame
 print("UI_PERSISTENCE_V5 checks=",checks," failed=",failures.size()," failures=",failures)
 quit(0 if failures.is_empty() else 1)
