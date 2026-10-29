extends SceneTree
const Save=preload("res://scripts/save_v5.gd")
const Meta=preload("res://scripts/meta_v5.gd")
const Build=preload("res://scripts/build_v5.gd")
var failures=[]
var checks=0
func check(value:bool,label:String)->void:
 checks+=1
 if not value:failures.append(label);printerr("FAIL ",label)
func _init()->void:
 var path="/tmp/starfront-save-v5-tests/run.json"
 var pp="/tmp/starfront-save-v5-tests/profile.json"
 DirAccess.make_dir_recursive_absolute(path.get_base_dir())
 for name in DirAccess.get_files_at(path.get_base_dir()):DirAccess.remove_absolute(path.get_base_dir().path_join(name))
 var r=Build.new_run("C01",93834)
 check(Save.validate_run(r),"new model state valid")
 check(Save.save_wave_start(r,path).ok,"wave start persists")
 r.wave=1;Build.settle_wave(r,0)
 check(r.cash==67,"zero pickup67")
 check(Save.save_run(r,path).ok,"shop transaction checkpoint")
 var loaded=Save.load_run(path)
 check(loaded.ok and JSON.stringify(loaded.run.shop)==JSON.stringify(r.shop),"exact offers restored")
 check(loaded.run.rng_state==r.rng_state and loaded.run.rng_seed==r.rng_seed,"64bit RNG decimal strings exact")
 check(loaded.run.level_choices==r.level_choices,"level options exact")
 r.cash+=10;check(Save.save_run(r,path).ok,"second checkpoint")
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string("truncated");f.close()
 loaded=Save.load_run(path)
 check(loaded.ok and loaded.recovered and loaded.run.cash==67,"corrupt main restores valid previous shop")
 var unknown=r.duplicate(true);unknown.weapons[0].id="W99"
 check(not Save.save_run(unknown,path).ok,"unknown content rejected without erasing")
 check(Save.load_run(path).ok,"unknown content rejection retains recoverable backup")
 r.rescue_spent=true;check(Save.save_rescue(r,path).ok,"spent rescue journal")
 loaded=Save.load_run(path)
 check(loaded.ok and loaded.run.rescue_spent,"backup cannot resurrect consumed rescue")
 r.rescue_spent=false;check(Save.save_rescue(r,path).ok,"false no-op does not clear journal")
 check(Save.load_run(path).run.rescue_spent,"monotone rescue")
 var f2=FileAccess.open(path+".rescue",FileAccess.WRITE);f2.store_string("damaged");f2.close()
 check(Save.load_run(path).run.rescue_spent,"damaged rescue conservative spent")
 check(Save.save_run(r,path).ok,"repair current from valid state")
 var before=FileAccess.get_file_as_bytes(path)
 DirAccess.make_dir_recursive_absolute(path+".bak.tmp")
 check(not Save.save_run(r,path).ok,"backup write failure fails transaction")
 check(FileAccess.get_file_as_bytes(path)==before,"backupfailure preserves primarybytes")
 DirAccess.remove_absolute(path+".bak.tmp")
 var p=Meta.new_profile()
 check(Save.validate_profile(p),"profile schema")
 check(not Meta.unlock(p,"C02").ok and p.research_data==0,"inactive content not sold")
 check(not Meta.set_enabled(p,"W01",false).ok,"starter cannot disabled")
 check(not Meta.set_enabled(p,"S01",false).ok,"minimum support pool4")
 var award=Meta.award(p,r,4,true)
 check(award.earned==10 and p.research_data==10,"act plusfirstboss reward")
 check(Meta.award(p,r,4,true).earned==0,"reward dedupe")
 var training=r.duplicate(true);training.mode="pressure";training.run_id="training"
 check(Meta.award(p,training,4,true).earned==0,"training no rewards")
 check(Meta.award(p,r,2,true).earned==0,"unfinishedact no reward")
 check(Save.save_profile(p,pp).ok,"profile andledger save")
 f=FileAccess.open(pp,FileAccess.WRITE);f.store_string("bad");f.close()
 var restored=Save.load_profile(pp)
 check(restored.research_data==10 and restored.recovered,"rewardledger recovery")
 check(Meta.award(restored,r,4,true).earned==0,"ledger reward cannot replay")
 f=FileAccess.open(pp+".ledger",FileAccess.WRITE);f.store_string("bad");f.close()
 var damaged=Save.load_profile(pp)
 check(damaged.has("load_error"),"unrecoverable profile not silently reset")
 check(not Save.save_profile(damaged,pp).ok,"corrupt profile refuses overwrite")
 var oldpaths=["user://run_v2.json","user://starfront_meta_v4.json","user://profile_v4.json"]
 for oldpath in oldpaths:
  var oldfile=FileAccess.open(oldpath,FileAccess.WRITE);oldfile.store_string("legacy-earned-power-and-rescue-spent");oldfile.close()
 check(Save.get_compatibility_notice().contains("原样保留"),"legacy compatibility explained")
 check(Save.clear_run(path).ok,"clear only v5run")
 for oldpath in oldpaths:check(FileAccess.get_file_as_string(oldpath)=="legacy-earned-power-and-rescue-spent","legacy bytes retained "+oldpath)
 var invalid=r.duplicate(true);invalid.rng_state="92233720368547758080"
 check(not Save.validate_run(invalid),"overflow RNG rejected")
 invalid=r.duplicate(true);invalid.level_choices=["legacy_permanent_damage"]
 check(not Save.validate_run(invalid),"unknown reward choice rejected")
 invalid=r.duplicate(true);invalid.research_choices=["T99"]
 check(not Save.validate_run(invalid),"unknown research rejected")
 print("SAVE_V5 ",checks," checks; failures=",failures)
 quit(0 if failures.is_empty() else 1)
