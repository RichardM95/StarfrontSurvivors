extends SceneTree
const Build=preload("res://scripts/build_v2.gd")
var g
func _initialize(): call_deferred("run")
func run():
 g=load("res://main.tscn").instantiate(); root.add_child(g);g.set_process(false)
 g.test_mode=true;g.auto_test=true;g.sound.muted=true
 await process_frame
 var args=OS.get_cmdline_user_args()
 var archetypes=["sniper","flame","shotgun"] if args.is_empty() else [args[0]]
 for archetype in archetypes:
  g.selected_class={"sniper":"ghost","flame":"firebat","shotgun":"marauder"}[archetype]
  g.rng.seed=int(args[1]) if args.size()>1 else 44212
  g.start_run()
  var ticks=0
  var shop_rolls=0
  var last_wave=0
  while g.state not in ["dead","victory"] and ticks<30000:
   ticks+=1
   if g.wave!=last_wave:
    last_wave=g.wave;shop_rolls=0
   if g.state=="wave":
    g.total_time+=0.033333
    if not g._nearest(125).is_empty(): g._dash()
    g._update_game(0.033333)
   elif g.state=="level":
    var best=0;var priority=-1
    for i in range(g.build.level_offers.size()):
     var id=g.build.level_offers[i]
     var score={"damage":7,"attack":6,"armor":7,"regen":9,"health":8,"lifesteal":8,"fortress":9,"revive":15,"turret":12,"extra_dash":10,"ballistic":8,"magnet":5}.get(id,3)
     if score>priority:priority=score;best=i
    g._choose_level(best)
   elif g.state=="branch":
    var idx=g._pending_branch()
    var id=g.weapons[idx].id
    g._choose_branch(idx,"b" if id in ["rifle","sniper","reaper"] else "a")
   elif g.state=="shop":
    var purchased=false
    for i in range(g.build.offers.size()):
     if g.state!="shop":break
     var o=g.build.offers[i]
     if o.is_empty():continue
     if o.cost>g.cash:continue
     var wanted=(o.type=="weapon" and o.id==archetype) or o.type=="upgrade" or (o.type=="item" and o.id in ["nanobot","exoskeleton","scope","tissue","core"])
     if wanted:
      if g._purchase(i):purchased=true
    if g.state=="shop" and not purchased:
     if shop_rolls<3 and g.cash>g.build.reroll_cost+50:
      g._reroll();shop_rolls+=1
     else:
      g._heal();g.start_wave()
   if ticks%300==0: await process_frame
  print("BUILD_RUN ",archetype," ",JSON.stringify({"state":g.state,"wave":g.wave,"kills":g.kills,"hp":g.hp,"max_hp":g.max_hp,"level":g.level,"time":ticks/30.0,"cash":g.cash,"weapons":g.weapons,"items":g.items,"damage":g.telemetry.damage_dealt}))
  await process_frame
 quit()
