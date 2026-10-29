extends SceneTree
## Integration-only accelerated simulation. No claim of real phone performance.
const Main = preload("res://scripts/main.gd")
const Build = preload("res://scripts/build_v2.gd")
const Save = preload("res://scripts/save_v2.gd")
const Meta = preload("res://scripts/meta_v4.gd")
const Combat = preload("res://scripts/combat_v2.gd")
const Narrative = preload("res://scripts/narrative_v4.gd")
var passed := 0
var failed := 0
var g
var dir := "/tmp/starfront-v4-integration-"+str(OS.get_process_id())
func _initialize(): call_deferred("run")
func ck(ok: bool, label: String):
 if ok: passed+=1
 else:
  failed+=1
  push_error("FAIL "+label)
 print(("PASS " if ok else "FAIL ")+label)
func settle():
 for i in range(30):
  if g.state=="level": g._choose_level(0)
  elif g.state=="branch": g._choose_branch(g._pending_branch(),"a")
  else: break
func complete_wave():
 g.combat.spawn=9999.0
 if Combat.is_boss_wave(g.wave):
  for e in g.enemies:
   if e.kind=="boss":
    e.hp=0
    Combat.kill_enemy(g,e)
    break
 else: g.phase_time=0
 g._update_game(0.001)
 settle()
func run():
 DirAccess.make_dir_recursive_absolute(dir)
 g=Main.new()
 g.test_mode=true
 g.save_path=dir+"/run.json"
 g.meta_path=dir+"/meta.json"
 root.add_child(g)
 g.set_process(false)
 g.sound.muted=true
 g.profile=Meta.new_profile()
 ck(Build.WEAPON_IDS.size()==8,"eight purchasable main weapon families")
 ck(Build.SUPPORT_IDS.size()==4,"four independent support equipment families")
 ck(Build.ITEM_IDS.size()>=40,"at least40 distinct item IDs")
 ck(Meta.TECH_IDS.size()==10,"ten tech tracks")
 for w in range(1,31):
  ck(not Narrative.wave_lines(w,"start").is_empty(),"wave%d ingress"%w)
  ck(not Narrative.wave_lines(w,"end").is_empty(),"wave%d egress"%w)
 ck(not Narrative.wave_lines(30,"phase2").is_empty() and not Narrative.wave_lines(30,"phase3").is_empty(),"final boss phase radio")
 g.start_run()
 var rid: String=g.run_id
 for w in range(1,31):
  ck(g.wave==w and g.state=="wave","enter wave%d"%w)
  if Combat.is_boss_wave(w):
   var bosses=g.enemies.filter(func(e):return e.kind=="boss")
   ck(bosses.size()==1,"one boss at%d"%w)
   if bosses.size(): ck(is_equal_approx(bosses[0].max_hp,{10:2800.0,20:6500.0,30:18000.0}[w]),"boss%d prescribed HP"%w)
  complete_wave()
  if w<30:
   ck(g.state=="shop","wave%d advances to shop, not victory"%w)
   g._sync_build()
   ck(Save.validate(g.build),"wave%d checkpoint valid"%w)
   var cash_before: int=g.cash
   var gas_before: int=g.profile.gas
   g.finish_wave()
   ck(g.cash==cash_before and g.profile.gas==gas_before,"wave%d duplicate finish inert"%w)
   g.start_wave()
  else: ck(g.state=="victory","wave30 final victory")
 ck(int(g.profile.get("wins",0))==1,"one metaprogression victory")
 var gas: int=g.profile.gas
 var genes: int=g.profile.genes
 g._end_run(true)
 ck(g.profile.gas==gas and g.profile.genes==genes and int(g.profile.wins)==1,"duplicate victory earns nothing")
 ck(int(g.profile.claimed.get(rid,{}).get("wave",0))==30,"ledger completed wave30")
 # New run dies before clearing W1: no cleared-wave reward.
 g.start_run()
 gas=g.profile.gas; genes=g.profile.genes
 g._end_run(false)
 ck(g.profile.gas==gas and g.profile.genes==genes,"death does not reward incomplete wave")
 # Persist W1, clear W2, reload an old checkpoint with the newer ledger.
 g.start_run(); complete_wave()
 g._sync_build()
 var old: Dictionary=g.build.duplicate(true)
 ck(Save.save_run(old,g.save_path),"isolated W1 checkpoint durable")
 ck(Meta.save_profile(g.profile,g.meta_path),"isolated W1 meta durable")
 g.start_wave(); complete_wave()
 ck(Meta.save_profile(g.profile,g.meta_path),"W2 ledger durable before stale replay")
 gas=g.profile.gas; genes=g.profile.genes
 ck(Save.save_run(old,g.save_path),"simulate stale checkpoint after kill/reload")
 g.profile=Meta.load_profile(g.meta_path)
 g._resume_run(); settle()
 ck(g.wave==1 and g.run_id==str(old.run_id),"reload preserves run identity and checkpoint")
 g.start_wave(); complete_wave()
 ck(g.profile.gas==gas and g.profile.genes==genes,"replayed W2 cannot duplicate currency")
 # Legacy v0.3.0 checkpoints remain readable with optional V4 state absent.
 var legacy: Dictionary=Build.new_run("marine")
 legacy.wave=9
 for key in ["supports","meta_bonuses","mastery","free_rerolls","run_id"]: legacy.erase(key)
 ck(Save.validate(legacy),"legacy V0.3 checkpoint validates")
 ck(Save.save_run(legacy,g.save_path),"legacy checkpoint persists")
 g._resume_run(); settle(); g.start_wave()
 ck(g.wave==10 and g.state=="wave","legacy W9 resumes at first boss")
 # Meta purchasing affects actual run stats, bounded and charged.
 var profile: Dictionary=Meta.new_profile();profile.gas=100000;profile.genes=100000
 for id in Meta.TECH_IDS:
  for n in range(int(Meta.TECH[id].max)): ck(Meta.buy_tech(profile,id),"buy tech %s level%d"%[id,n+1])
  var amount: int=profile.gas
  ck(not Meta.buy_tech(profile,id) and profile.gas==amount,"max tech %s does not charge"%id)
 for id in Meta.MASTERY_IDS:
  for n in range(3): ck(Meta.buy_mastery(profile,id),"buy mastery %s star%d"%[id,n+1])
 var b: Dictionary=Build.new_run("marine")
 Meta.start_run(profile,b)
 var stats: Dictionary=Build.recompute(b)
 ck(is_equal_approx(stats.max_hp,130.0),"max health tech +30")
 ck(is_equal_approx(stats.regen,1.5),"max regeneration tech +1.5")
 ck(is_equal_approx(stats.damage_mult,1.15),"damage tech +15%")
 ck(is_equal_approx(stats.salvage_rate,0.9),"salvage90% recompute")
 ck(is_equal_approx(stats.dash_cooldown,3.5*0.75),"dash cooldown tech -25%")
 ck(int(b.free_rerolls)==2,"antenna grants two rerolls")
 b.items=["core","pump"]
 stats=Build.recompute(b)
 ck(is_equal_approx(stats.max_hp,125.0),"pump mastery HP penalty only5")
 ck(is_equal_approx(stats.attack_mult,0.925),"core mastery attack penalty7.5%")
 ck(is_equal_approx(stats.rifle_branch_penalty,0.9),"rifle mastery pierce penalty10%")
 b.supports=Build.SUPPORT_IDS.duplicate()
 stats=Build.recompute(b)
 ck(b.weapons.size()==1 and int(stats.synergies.engineering)>=4,"four supports consume no weapon slots")
 ck(is_equal_approx(stats.engineering_shield,30.0),"engineering4 provides30 shield")
 # Actual salvage payout uses computed rate, not additive bonus alone.
 g.profile=profile;g.start_run()
 g.drops.clear();g.drops.append({"value":100,"p":g.player,"age":0.0})
 var before: int=g.cash
 g.finish_wave()
 ck(g.cash-before==120,"W1 salvage100 pays90 plus30 clear reward")
 # Fault injection: a file used as a parent directory forces meta write failure.
 g.profile=Meta.new_profile();g.start_run()
 var blocker:=FileAccess.open(dir+"/not-a-directory",FileAccess.WRITE)
 blocker.store_string("fault injection");blocker.close()
 var good_meta: String=g.meta_path
 g.meta_path=dir+"/not-a-directory/meta.json"
 var baseline: Dictionary=g.build.duplicate(true);baseline.wave=0
 ck(Save.save_run(baseline,g.save_path),"failure baseline checkpoint persisted")
 g.test_mode=false;g.auto_test=false
 before=g.cash;gas=g.profile.gas
 g.finish_wave()
 ck(g.state=="wave" and g.cash==before and g.profile.gas==gas,"failed reward write blocks wave completion and rolls back")
 ck(int(Save.load_run(g.save_path).get("wave",-1))==0,"failed reward never advances checkpoint")
 g.meta_path=good_meta;g.finish_wave();settle()
 ck(g.state=="shop" and g.profile.gas==gas+3,"reward save retry completes exactly once")
 ck(int(Save.load_run(g.save_path).get("wave",-1))==1,"retry durable checkpoint advances")
 # Victory must retain the last safe checkpoint until win currency is durable.
 g.test_mode=true;g.start_run();g.wave=30
 baseline=g.build.duplicate(true);baseline.wave=29
 ck(Save.save_run(baseline,g.save_path),"pre-victory checkpoint persisted")
 g.meta_path=dir+"/not-a-directory/meta.json"
 g.test_mode=false;gas=g.profile.gas
 g._end_run(true)
 ck(g.state=="wave" and int(g.profile.wins)==0 and g.profile.gas==gas,"failed victory reward remains playable and rolls back win")
 ck(not Save.load_run(g.save_path).is_empty(),"failed victory retains recovery checkpoint")
 g.meta_path=good_meta;g._end_run(true)
 ck(g.state=="victory" and int(g.profile.wins)==1,"victory retry credits one win")
 ck(Save.load_run(g.save_path).is_empty(),"committed victory clears checkpoint")
 g.test_mode=true
 g.queue_free()
 await process_frame
 print("INTEGRATION_V4_TEST passed=%d failed=%d"%[passed,failed])
 quit(0 if failed==0 else 1)
