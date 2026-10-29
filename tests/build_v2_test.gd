extends SceneTree
const B = preload("res://scripts/build_v2.gd")
var checks := 0
var failures := 0
var rng := RandomNumberGenerator.new()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok: failures+=1; push_error(label)
func _initialize()->void:
 rng.seed=2345
 for cls in B.CLASS_IDS:
  var s:=B.new_run(cls)
  check(s.weapons.size()==1,"one starter "+cls)
  check(s.hp==B.recompute(s).max_hp,"class hp "+cls)
  check(s.pending_branch==-1,"no pending branch "+cls)
  check(s.cash==35,"starting cash "+cls)
 var s:=B.new_run("marine")
 check(B.recompute(s).max_hp==100,"marine hp")
 var m:=B.recompute(B.new_run("marauder"))
 check(absf(m.armor/(m.armor+50)-0.15)<0.0001,"marauder armor conversion")
 check(B.recompute(B.new_run("ghost")).crit_mult==2.0,"ghost critical")
 check(B.recompute(B.new_run("reaper")).dash_cooldown==2.4,"reaper cooldown")
 s.cash=5000; s.wave=1
 for i in range(3):
  s.offers=[{"type":"weapon","id":"rifle","cost":30},{},{},{}]
  check(B.buy(s,0).ok,"duplicate rifle allowed")
 check(s.weapons.size()==4,"four slots")
 check(B.recompute(s).synergies.ballistic==4 and B.recompute(s).synergies.hightech==4,"tag counts by slot")
 var before:=int(s.cash)
 s.offers=[{"type":"weapon","id":"rifle","cost":30},{},{},{}]
 check(not B.buy(s,0).ok and s.cash==before,"full slots cannot charge")
 for i in range(2):
  s.offers=[{"type":"upgrade","id":"rifle","uid":1,"from_level":i+1,"cost":50},{},{},{}]
  check(B.buy(s,0).ok,"upgrade rifle")
 check(s.pending_branch==0 and s.weapons[0].level==3,"Lv3 pending branch")
 check(B.sell(s,1)==-1,"pending branch blocks sale")
 check(not B.select_branch(s,0,"invalid"),"invalid branch")
 check(B.select_branch(s,0,"a"),"select a")
 check(not B.select_branch(s,0,"b"),"branch mutually exclusive")
 s.offers=[{"type":"upgrade","id":"rifle","uid":1,"from_level":3,"cost":60},{},{},{}]
 check(B.buy(s,0).ok,"Lv4 upgrade")
 B.roll_shop(s,rng)
 for offer in s.offers:
  check(not (offer.get("type","")=="upgrade" and offer.get("uid",-1)==1),"max gun filtered")
 var refund:=B.sell(s,0)
 check(refund==80,"sale half cumulative actual spend")
 check(s.weapons.size()==3,"slot freed")
 B.roll_shop(s,rng)
 check(B.toggle_lock(s,0),"lock")
 var locked:Dictionary=s.offers[0].duplicate(true)
 s.wave=2; B.begin_shop(s,rng)
 check(s.offers[0]==locked and s.locks[0],"locked offer retained wave")
 B.reroll_shop(s,rng)
 check(s.offers[0]==locked,"locked offer retained reroll")
 s.locks=[true,true,true,true]
 before=int(s.cash)
 check(not B.reroll_shop(s,rng) and s.cash==before,"all locks no charge")
 s=B.new_run("marine"); s.cash=5000
 for id in ["pump","core","reactor","exoskeleton","nanobot","scope","tissue","storage","tripod","injector"]:
  s.offers=[{"type":"item","id":id,"cost":40},{},{},{}]
  check(B.buy(s,0).ok,"buy item "+id)
  var paid:=int(s.cash)
  s.offers=[{"type":"item","id":id,"cost":40},{},{},{}]
  check(not B.buy(s,0).ok and s.cash==paid,"unique item "+id)
 var stats:=B.recompute(s)
 check(stats.max_hp==95,"item hp tradeoffs")
 check(absf(stats.speed_mult-1.08)<0.0001,"item speed tradeoffs")
 check(absf(stats.attack_mult-1.25*0.85)<0.0001,"interval penalty applies all bonuses")
 check(stats.hurt_extra==4 and stats.hurt_invuln==1.0,"item incoming damage effects")
 check(stats.heal_cost_mult==1.5 and stats.wave_subsidy==25 and stats.enemy_scale==1.05,"economy tradeoffs")
 check(stats.regen==2.5 and stats.pickup_radius==110,"regen and pickup")
 s=B.new_run("marine")
 check(B.sell(s,0)==-1,"last weapon protected")
 B.gain_xp(s,50)
 check(s.level==3 and s.pending_levels==2 and s.xp==10,"queued xp levels")
 check(s.hp==100 and B.recompute(s).damage_mult==1,"no automatic level buff")
 s.cash=100
 B.roll_level(s,rng)
 check(s.level_offers.size()==3,"three choices")
 check(s.level_offers[0]!=s.level_offers[1] and s.level_offers[0]!=s.level_offers[2],"unique choices")
 check(B.level_reroll_cost(s)==0 and B.reroll_level(s,rng) and s.cash==100,"free reroll")
 check(B.level_reroll_cost(s)==5 and B.reroll_level(s,rng) and s.cash==95,"five reroll")
 check(B.level_reroll_cost(s)==10 and B.reroll_level(s,rng) and s.cash==85,"ten reroll")
 check(not B.reroll_level(s,rng) and s.cash==85,"reroll cap")
 s.level_offers=["health","damage","armor"]
 check(B.apply_level(s,0) and s.hp==112 and s.pending_levels==1,"selected hp growth")
 check(s.level_rerolls==0 and s.level_offers.is_empty(),"next level resets rerolls")
 check(not B.apply_level(s,0),"double click prevented")
 for id in B.LEVEL_CARDS:
  var test:=B.new_run("marine"); test.pending_levels=1; test.level_offers=[id]
  check(B.apply_level(test,0),"apply each card "+str(id))
 s.bonuses={"speed_mult":8.0,"dodge":1.0,"crit_rate":2.0,"lifesteal":2.0,"range_mult":5.0}
 stats=B.recompute(s)
 check(stats.speed_mult==1.7 and stats.dodge==0.5 and stats.crit_rate==1.0,"caps")
 for i in range(50):
  B.roll_level(s,rng)
  check(not s.level_offers.has("speed") and not s.level_offers.has("dodge") and not s.level_offers.has("crit"),"capped cards filtered")
 var totals:={0:0,1:0,2:0}
 s=B.new_run("marine")
 for i in range(2000):
  B.roll_level(s,rng)
  for id in s.level_offers: totals[int(B.LEVEL_CARDS[id].rarity)]+=1
 check(totals[0]>3500 and totals[1]>1000 and totals[2]>150,"rarity distribution")
 print("BUILD_V2: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
