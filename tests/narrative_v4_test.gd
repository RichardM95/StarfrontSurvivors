extends SceneTree
const N=preload("res://scripts/narrative_v4.gd")
const R=preload("res://scripts/radio_v4.gd")
var checks=0
var failures=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok: failures+=1;push_error(label)
func _initialize()->void:
 for wave in range(1,31):
  check(not N.wave_lines(wave).is_empty(),"start %s"%wave)
  check(not N.wave_lines(wave,"end").is_empty(),"end %s"%wave)
  check(N.wave_name(wave)!="未知战区","name %s"%wave)
 check(N.wave_lines(30,"phase2").size()==3,"phase2")
 check(N.wave_lines(30,"phase3").size()==2,"phase3")
 check(N.wave_lines(20,"end").size()==6,"W20 transition complete")
 check(N.wave_lines(30,"end").size()==7,"ending complete")
 check(N.bark("overcharge").size()==2,"overcharge")
 check(N.shop({"hp":20,"max_hp":100})[0].speaker=="艾拉","lowhp")
 check(N.shop({"cash":500})[0].speaker=="汉克","rich")
 check(N.shop({"rerolls":3})[0].speaker=="副官 23-C","reroll")
 check(not N.bridge("baneling").is_empty(),"death")
 var radio=R.new();root.add_child(radio);radio.setup()
 radio.clear_queue();radio.import_history([])
 radio.play(N.wave_lines(1))
 check(radio.current.speaker=="副官 23-C","first line")
 check(radio.pending.size()==2,"queued lines")
 radio.play(N.wave_lines(30,"phase2"),true)
 check(radio.pending.size()==5,"priority retains pending")
 check(radio.history.size()==6,"log all supplied lines")
 radio.advance();check(radio.chars>0,"reveal")
 radio.advance();check(radio.current.speaker=="柯林斯上尉","next")
 radio.set_display_enabled(false);check(not radio.panel.visible,"hide")
 radio.show_history();check(radio.history_window.visible,"history")
 radio.import_history([{"invalid":1}]);check(radio.history.is_empty(),"validate")
 radio.queue_free()
 print("NARRATIVE CHECKS ",checks," FAILURES ",failures)
 quit(failures)
