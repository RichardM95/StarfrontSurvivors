extends SceneTree
const B=preload("res://scripts/build_v2.gd")
const M=preload("res://scripts/meta_v4.gd")
var n:=0
var failures:=0
func check(ok:bool,label:String)->void:
 n+=1
 if not ok: failures+=1; push_error(label)
func _initialize()->void:
 var s:=B.new_run()
 check(B.WEAPON_IDS.size()==8,"eight main weapons")
 check(B.ITEM_IDS.size()>=40,"forty plus items")
 check(B.SUPPORT_IDS.size()==4,"four supports")
 for id in B.ITEM_IDS:
  var fresh:=B.new_run();fresh.cash=999;fresh.offers=[{"type":"item","id":id,"cost":40},{},{},{}]
  check(B.buy(fresh,0).ok,"buy item "+id)
  var before:=B.recompute(B.new_run());var after:=B.recompute(fresh)
  check(before!=after or id=="tripod","meaningful item "+id)
  fresh.offers=[{"type":"item","id":id,"cost":40},{},{},{}]
  check(not B.buy(fresh,0).ok,"duplicate filtered "+id)
 for id in B.WEAPON_IDS:
  var fresh:=B.new_run();fresh.cash=999;fresh.offers=[{"type":"weapon","id":id,"cost":30},{},{},{}]
  check(B.buy(fresh,0).ok,"buy weapon "+id)
  check(B.branch_names(id).size()==2 and B.branch_descriptions(id).size()==2,"branches defined "+id)
 s.cash=999
 for id in B.SUPPORT_IDS:
  s.offers=[{"type":"support","id":id,"cost":60},{},{},{}]
  check(B.buy(s,0).ok,"buy support "+id)
 check(s.weapons.size()==1 and s.supports.size()==4,"supports separate slots")
 check(B.recompute(s).synergies.engineering==4,"engineering tags")
 check(B.recompute(s).engineering_shield==30 and B.recompute(s).support_attack_mult==1.25,"engineering effects")
 var rng:=RandomNumberGenerator.new();rng.seed=1947
 for i in range(20):
  B.roll_shop(s,rng)
  for offer in s.offers: check(offer.get("type","")!="support","owned supports filtered")
 var p:=M.new_profile()
 check(M.valid(p),"new meta valid")
 check(M.TECH_IDS.size()==10,"ten technologies")
 check(not M.buy_tech(p,"health"),"insufficient currency no purchase")
 p.gas=100000;p.genes=10000
 for id in M.TECH_IDS:
  for i in range(int(M.TECH[id].max)): check(M.buy_tech(p,id),"tech purchase "+id)
  check(not M.buy_tech(p,id),"tech cap "+id)
 for id in M.MASTERY_IDS:
  for i in range(3):check(M.buy_mastery(p,id),"mastery purchase "+id)
  check(not M.buy_mastery(p,id),"mastery cap "+id)
 s=M.start_run(p,B.new_run());var stats:=B.recompute(s)
 check(stats.max_hp==130 and stats.armor==10 and absf(stats.regen-1.5)<0.001,"meta survival stats")
 check(absf(stats.dash_cooldown-2.625)<0.001 and absf(stats.salvage_rate-.9)<0.001,"meta capped cooldown recovery")
 check(s.free_rerolls==2,"two free shop rerolls per run")
 s.cash=0;B.begin_shop(s,rng)
 check(B.reroll_shop(s,rng) and B.reroll_shop(s,rng),"use two free rerolls")
 B.begin_shop(s,rng)
 check(s.free_rerolls==0 and not B.reroll_shop(s,rng),"next wave cannot replenish free tokens")
 var mastered:=B.new_run();mastered.mastery=p.mastery.duplicate(true);mastered.items=["core","pump"]
 stats=B.recompute(mastered)
 check(absf(stats.attack_mult-.925)<.001,"three star core")
 check(stats.max_hp==95,"three star pump")
 check(absf(stats.rifle_branch_penalty-.9)<.001,"three star rifle")
 var reward_p:=M.new_profile()
 for wave in range(1,31):
  check(M.reward(reward_p,"run-A",wave,wave==30).ok,"reward wave %d"%wave)
  var snapshot:=reward_p.duplicate(true)
  check(not M.reward(reward_p,"run-A",wave,wave==30).ok and snapshot==reward_p,"idempotent wave %d"%wave)
 check(reward_p.wins==1 and reward_p.best_wave==30,"win counted once")
 check(not M.reward(reward_p,"run-A",1).ok,"old checkpoint cannot farm")
 check(M.reward(reward_p,"run-B",1).ok,"new run reward")
 var path:="user://meta_v4_test.json"
 check(M.save_profile(reward_p,path),"atomic save")
 check(M.load_profile(path)==reward_p,"load exact profile")
 var first:=reward_p.duplicate(true)
 M.reward(reward_p,"run-B",2);check(M.save_profile(reward_p,path),"rotate backup")
 var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string("corrupt");f.close()
 check(M.load_profile(path)==first,"corrupt main recovers backup")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 var invalid:=M.new_profile();invalid.gas=-1
 check(not M.valid(invalid) and not M.save_profile(invalid,path),"negative currency rejected")
 for bad in ["999",-1,1.25,INF,NAN]:
  invalid=M.new_profile();invalid.gas=bad
  check(not M.valid(invalid),"reject malformed currency")
 invalid=M.new_profile();invalid.tech={"health":6}
 check(not M.valid(invalid),"reject excessive rank")
 invalid=M.new_profile();invalid.tech={"health":"5"}
 check(not M.valid(invalid),"reject string rank")
 var capped:=B.new_run();capped.bonuses={"crit_rate":1.0,"range_mult":2.0};capped.cash=100
 capped.offers=[{"type":"item","id":"target_chip","cost":1},{},{},{}]
 check(not B.buy(capped,0).ok,"filter no-benefit capped item")
 var old_reward:=reward_p.duplicate(true)
 check(not M.reward(reward_p,"",1).ok and not M.reward(reward_p,"run-C",31).ok and reward_p==old_reward,"bad rewards immutable")
 print("BUILD_META_V4: ",n," checks, ",failures," failures")
 quit(1 if failures else 0)
